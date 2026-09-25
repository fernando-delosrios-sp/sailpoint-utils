import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, isOfflineContext, OperationSignature, RequestContext } from '../../framework'
import { EntitlementRef, listEntitlementsByValue, listEntitlementsByValues } from '../../isc/entitlements'
import { listMachineAccounts, MachineAccountRecord } from '../../isc/machine-accounts'
import {
    getMachineIdentity,
    listMachineIdentities,
    listMachineIdentitiesOffline,
    MachineIdentityRecord,
    patchUserEntitlements,
    resolveMachineIdentityByIdentityId,
    unionUserEntitlements,
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
        'machine-identity-entitlements:identities-scanned': number
        'machine-identity-entitlements:identities-updated': number
        'machine-identity-entitlements:identities-skipped': number
        'machine-identity-entitlements:identities-failed': number
        'machine-identity-entitlements:entitlements-added': number
        'machine-identity-entitlements:failed-identity-ids': string[]
        'machine-identity-entitlements:failure-details': string[]
    }
    response: {
        identitiesScanned?: number
        identitiesUpdated?: number
        identitiesSkipped?: number
        identitiesFailed?: number
        entitlementsAdded?: number
    }
}

const PATCH_CONCURRENCY = 5

interface OperationSummary {
    identitiesScanned: number
    identitiesUpdated: number
    identitiesSkipped: number
    identitiesFailed: number
    entitlementsAdded: number
}

interface IdentityApplyResult {
    status: 'updated' | 'skipped' | 'failed'
    addedCount: number
    identityId: string
    failureDetail?: string
}

/** Evaluates machine identities, applies user-entitlement unions, and persists one scan summary. */
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
            const summary = emptySummary()
            await persistSummary(ctx, summary, [], 'success')
            ctx.respond(summary)
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
        const pendingUpdates: Array<{ identityId: string; matched: EntitlementRef[] }> = []
        let identitiesSkipped = 0
        const initialFailures: IdentityApplyResult[] = []

        for (const [machineIdentityId, identityAccounts] of accountsByIdentity) {
            const identity = identitiesById.get(machineIdentityId)
            if (!identity) {
                ctx.log.warn('Machine account references an unavailable machine identity', { machineIdentityId })
                initialFailures.push({
                    status: 'failed',
                    addedCount: 0,
                    identityId: machineIdentityId,
                    failureDetail: 'Machine account references an unavailable machine identity',
                })
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
                identitiesSkipped += 1
                continue
            }

            pendingUpdates.push({ identityId: identity.id, matched })
        }

        const applyResults = await mapWithConcurrency(pendingUpdates, PATCH_CONCURRENCY, async (update) => {
            try {
                const current = offline
                    ? identitiesById.get(update.identityId)
                    : await getMachineIdentity(ctx.sdk.machineIdentities, update.identityId)
                if (!current) {
                    throw new ConnectorError(`Machine identity not found: ${update.identityId}`)
                }

                const additions = entitlementsToAdd(update.matched, current.userEntitlements)
                if (additions.length === 0) {
                    return {
                        status: 'skipped',
                        addedCount: 0,
                        identityId: update.identityId,
                    } satisfies IdentityApplyResult
                }

                const union = unionUserEntitlements(
                    current.userEntitlements,
                    additions.map((entitlement) => ({
                        sourceId: entitlement.sourceId,
                        entitlementId: entitlement.id,
                    }))
                )
                if (!offline) {
                    await patchUserEntitlements(ctx.sdk.machineIdentities, update.identityId, union)
                }
                return {
                    status: 'updated',
                    addedCount: additions.length,
                    identityId: update.identityId,
                } satisfies IdentityApplyResult
            } catch (error) {
                const failureDetail = error instanceof Error ? error.message : String(error)
                ctx.log.warn('Failed to apply machine identity entitlements', {
                    machineIdentityId: update.identityId,
                    error: failureDetail,
                })
                return {
                    status: 'failed',
                    addedCount: 0,
                    identityId: update.identityId,
                    failureDetail,
                } satisfies IdentityApplyResult
            }
        })

        const results = [...initialFailures, ...applyResults]
        const failures = results.filter((result) => result.status === 'failed')
        const summary: OperationSummary = {
            identitiesScanned: accountsByIdentity.size,
            identitiesUpdated: results.filter((result) => result.status === 'updated').length,
            identitiesSkipped: identitiesSkipped + results.filter((result) => result.status === 'skipped').length,
            identitiesFailed: failures.length,
            entitlementsAdded: results.reduce((total, result) => total + result.addedCount, 0),
        }
        const summaryStatus = summary.identitiesFailed === 0 ? 'success' : summary.identitiesUpdated > 0 ? 'partial' : 'failed'
        await persistSummary(ctx, summary, failures, summaryStatus)
        ctx.respond(summary, summaryStatus === 'failed' ? 'failed' : 'success')
    },
    { operationSchema: machineIdentityEntitlementsOperationSchema }
)

function emptySummary(): OperationSummary {
    return {
        identitiesScanned: 0,
        identitiesUpdated: 0,
        identitiesSkipped: 0,
        identitiesFailed: 0,
        entitlementsAdded: 0,
    }
}

async function persistSummary(
    ctx: RequestContext<
        MachineIdentityEntitlementsOperation['output'],
        MachineIdentityEntitlementsOperation['response']
    >,
    summary: OperationSummary,
    failures: readonly IdentityApplyResult[],
    status: 'success' | 'partial' | 'failed'
): Promise<void> {
    await ctx.persist(
        ctx.requestId,
        {
            'machine-identity-entitlements:identities-scanned': summary.identitiesScanned,
            'machine-identity-entitlements:identities-updated': summary.identitiesUpdated,
            'machine-identity-entitlements:identities-skipped': summary.identitiesSkipped,
            'machine-identity-entitlements:identities-failed': summary.identitiesFailed,
            'machine-identity-entitlements:entitlements-added': summary.entitlementsAdded,
            'machine-identity-entitlements:failed-identity-ids': failures.map((failure) => failure.identityId),
            'machine-identity-entitlements:failure-details': failures.map(
                (failure) => failure.failureDetail ?? 'Unknown identity apply failure'
            ),
        },
        status
    )
}

async function mapWithConcurrency<T, R>(
    items: readonly T[],
    limit: number,
    run: (item: T) => Promise<R>
): Promise<R[]> {
    let next = 0
    const results = new Array<R>(items.length)
    const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
        while (next < items.length) {
            const index = next++
            results[index] = await run(items[index])
        }
    })
    await Promise.all(workers)
    return results
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
