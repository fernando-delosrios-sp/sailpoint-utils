import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, isOfflineContext, OperationSignature } from '../../framework'
import { EntitlementRef, listEntitlementsByValue, listEntitlementsByValues } from '../../isc/entitlements'
import { listMachineAccounts, MachineAccountRecord } from '../../isc/machine-accounts'
import {
    listMachineIdentities,
    listMachineIdentitiesOffline,
    MachineIdentityRecord,
    resolveMachineIdentityByIdentityId,
} from '../../isc/machine-identities'
import { getSource, SourcePayload } from '../../isc/sources'
import { entitlementsToAdd, extractInboundValues, userEntitlementsAttributeName } from './evaluate'
import { machineIdentityEntitlementsOperationSchema } from './index.schema'
import {
    getOfflineSource,
    listEntitlementsByValueOffline,
    listMachineAccountsOffline,
    resolveMachineIdentityByIdentityIdOffline,
} from './offline-data'

export interface MachineIdentityEntitlementsOperation extends OperationSignature {
    command: 'custom:machine-identity-entitlements'
    input: {
        identityId?: string
    }
    output: {
        'machine-identity-entitlements:machine-identity-id': string
        'machine-identity-entitlements:entitlement-ids': string[]
        'machine-identity-entitlements:entitlement-source-ids': string[]
    }
    response: {
        identitiesScanned?: number
        triggerAccountsWritten?: number
    }
}

const PERSIST_CONCURRENCY = 5

/** Evaluates machine identities and persists entitlements to add on one trigger account per identity with work. */
export const machineIdentityEntitlementsOperation = customOperation<MachineIdentityEntitlementsOperation>(
    async (ctx, input) => {
        const offline = isOfflineContext(ctx)
        const identityId = typeof input.identityId === 'string' ? input.identityId.trim() : ''
        const targetIdentity = identityId
            ? offline
                ? resolveMachineIdentityByIdentityIdOffline(identityId)
                : await resolveMachineIdentityByIdentityId(ctx.sdk.machineIdentities, identityId)
            : undefined
        if (identityId && !targetIdentity) {
            throw new ConnectorError(`Machine identity not found: ${identityId}`)
        }

        const allAccounts = offline ? listMachineAccountsOffline() : await listMachineAccounts(ctx.sdk.machineAccounts)
        const accounts = targetIdentity
            ? allAccounts.filter((account) => account.machineIdentity.id === targetIdentity.id)
            : allAccounts
        const sourceCache = new Map<string, SourcePayload | undefined>()
        await Promise.all(
            [...new Set(accounts.map((account) => account.source.id))].map((sourceId) =>
                loadSource(ctx, offline, sourceId, sourceCache)
            )
        )
        const valuesByAccount = new Map<string, string[]>()
        const eligibleAccounts = accounts.filter((account) => {
            const attributeName = userEntitlementsAttributeName(sourceCache.get(account.source.id))
            if (!attributeName) {
                return false
            }
            const values = extractInboundValues(account.connectorAttributes[attributeName])
            if (values.length === 0) {
                return false
            }
            valuesByAccount.set(account.id, values)
            return true
        })
        const accountsByIdentity = groupByMachineIdentity(eligibleAccounts)
        if (accountsByIdentity.size === 0) {
            ctx.respond({ identitiesScanned: 0, triggerAccountsWritten: 0 })
            return
        }
        const identities = targetIdentity
            ? [targetIdentity]
            : offline
            ? listMachineIdentitiesOffline()
            : await listMachineIdentities(ctx.sdk.machineIdentities)
        const identitiesById = new Map(identities.map((identity) => [identity.id, identity]))
        const allValues = [...new Set([...valuesByAccount.values()].flat())]
        const batchedCatalog =
            targetIdentity || offline ? undefined : await listEntitlementsByValues(ctx.sdk.entitlements, allValues)
        const entitlementCache = new Map<string, EntitlementRef[]>()
        const pendingWrites: Array<{ persistId: string; identityId: string; toAdd: EntitlementRef[] }> = []

        for (const [machineIdentityId, identityAccounts] of accountsByIdentity) {
            const identity = identitiesById.get(machineIdentityId)
            if (!identity) {
                ctx.log.warn('Machine account references an unavailable machine identity', { machineIdentityId })
                continue
            }

            const matched: EntitlementRef[] = []
            for (const account of identityAccounts) {
                const sourceId = account.source.id
                for (const value of valuesByAccount.get(account.id) ?? []) {
                    let catalog = entitlementCache.get(value)
                    if (!catalog) {
                        catalog = batchedCatalog
                            ? batchedCatalog.filter((entitlement) => entitlement.value === value)
                            : offline
                            ? listEntitlementsByValueOffline(value)
                            : await listEntitlementsByValue(ctx.sdk.entitlements, value)
                        entitlementCache.set(value, catalog)
                    }
                    if (catalog.length === 0) {
                        ctx.log.warn('Unmatched machine-account entitlement value skipped', {
                            machineIdentityId: identity.id,
                            sourceId,
                            value,
                        })
                        continue
                    }
                    matched.push(...catalog)
                }
            }

            const toAdd = entitlementsToAdd(matched, identity.userEntitlements)
            if (toAdd.length === 0) {
                continue
            }

            pendingWrites.push({ persistId: `${ctx.requestId}:${identity.id}`, identityId: identity.id, toAdd })
        }

        // Each trigger account waits on its own ISC provisioning task, so a tenant-wide scan only
        // fits inside the workflow invoke timeout when those waits overlap.
        await forEachWithConcurrency(pendingWrites, PERSIST_CONCURRENCY, async (write) => {
            await ctx.persist(write.persistId, {
                'machine-identity-entitlements:machine-identity-id': write.identityId,
                'machine-identity-entitlements:entitlement-ids': write.toAdd.map((entitlement) => entitlement.id),
                'machine-identity-entitlements:entitlement-source-ids': write.toAdd.map(
                    (entitlement) => entitlement.sourceId
                ),
            })
        })

        ctx.respond({
            identitiesScanned: accountsByIdentity.size,
            triggerAccountsWritten: pendingWrites.length,
        })
    },
    { operationSchema: machineIdentityEntitlementsOperationSchema }
)

async function forEachWithConcurrency<T>(
    items: readonly T[],
    limit: number,
    run: (item: T) => Promise<void>
): Promise<void> {
    let next = 0
    const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
        while (next < items.length) {
            await run(items[next++])
        }
    })
    await Promise.all(workers)
}

function groupByMachineIdentity(accounts: MachineAccountRecord[]): Map<string, MachineAccountRecord[]> {
    const grouped = new Map<string, MachineAccountRecord[]>()
    for (const account of accounts) {
        const identityId = account.machineIdentity.id
        grouped.set(identityId, [...(grouped.get(identityId) ?? []), account])
    }
    return grouped
}

async function loadSource(
    ctx: { sdk: { sources: Parameters<typeof getSource>[0] } },
    offline: boolean,
    sourceId: string,
    cache: Map<string, SourcePayload | undefined>
): Promise<SourcePayload | undefined> {
    if (cache.has(sourceId)) {
        return cache.get(sourceId)
    }
    const source = offline ? getOfflineSource(sourceId) : await getSource(ctx.sdk.sources, sourceId)
    cache.set(sourceId, source)
    return source
}
