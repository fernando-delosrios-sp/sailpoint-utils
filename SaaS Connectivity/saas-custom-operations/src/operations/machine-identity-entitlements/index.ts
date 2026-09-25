import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, isOfflineContext, OperationSignature } from '../../framework'
import { escapeODataString, listAccounts } from '../../isc/accounts'
import { listEntitlementsByValue } from '../../isc/entitlements'
import {
    listMachineIdentities,
    MachineIdentityRecord,
    resolveMachineIdentityByIdentityId,
} from '../../isc/machine-identities'
import { getAccountSchema, SchemaPayload } from '../../isc/sources'
import { entitlementsToAdd, extractInboundValues, inboundAttributeName } from './evaluate'
import { machineIdentityEntitlementsOperationSchema } from './index.schema'
import {
    getOfflineAccountSchema,
    identityCorrelationKey,
    listEntitlementsByValueOffline,
    listMachineIdentitiesOffline,
    listOfflineUnderlyingAccounts,
    resolveMachineIdentityByIdentityIdOffline,
} from './offline-data'

const ACCOUNT_PAGE_SIZE = 250

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

interface UnderlyingAccount {
    sourceId?: string
    attributes?: unknown
}

/** Evaluates machine identities and persists entitlements to add on one trigger account per identity with work. */
export const machineIdentityEntitlementsOperation = customOperation<MachineIdentityEntitlementsOperation>(
    async (ctx, input) => {
        const offline = isOfflineContext(ctx)
        const identityId = typeof input.identityId === 'string' ? input.identityId.trim() : ''
        const identities = await loadMachineIdentities(ctx, offline, identityId || undefined)

        const schemaCache = new Map<string, SchemaPayload | undefined>()
        let triggerAccountsWritten = 0

        for (const identity of identities) {
            const correlationKey = identityCorrelationKey(identity)
            const accounts = offline
                ? listOfflineUnderlyingAccounts(correlationKey)
                : await listUnderlyingAccounts(ctx.sdk.accounts, correlationKey)

            const inboundValues = new Set<string>()
            for (const account of accounts) {
                const sourceId = account.sourceId
                if (!sourceId) {
                    continue
                }
                const schema = await loadSchema(ctx, offline, sourceId, schemaCache)
                const attributeName = inboundAttributeName(schema)
                if (!attributeName) {
                    continue
                }
                const attributes = (account.attributes ?? {}) as Record<string, unknown>
                for (const value of extractInboundValues(attributes[attributeName])) {
                    inboundValues.add(value)
                }
            }

            const matched = []
            for (const value of inboundValues) {
                const catalog = offline
                    ? listEntitlementsByValueOffline(value)
                    : await listEntitlementsByValue(ctx.sdk.entitlements, value)
                if (catalog.length === 0) {
                    ctx.log.warn('Unmatched inbound entitlement value skipped', {
                        machineIdentityId: identity.id,
                        value,
                    })
                    continue
                }
                matched.push(...catalog)
            }

            const toAdd = entitlementsToAdd(matched, identity.userEntitlements)
            if (toAdd.length === 0) {
                continue
            }

            const persistId = `${ctx.requestId}:${identity.id}`
            await ctx.persist(persistId, {
                'machine-identity-entitlements:machine-identity-id': identity.id,
                'machine-identity-entitlements:entitlement-ids': toAdd.map((entitlement) => entitlement.id),
                'machine-identity-entitlements:entitlement-source-ids': toAdd.map(
                    (entitlement) => entitlement.sourceId
                ),
            })
            triggerAccountsWritten += 1
        }

        ctx.respond({
            identitiesScanned: identities.length,
            triggerAccountsWritten,
        })
    },
    { operationSchema: machineIdentityEntitlementsOperationSchema }
)

async function loadMachineIdentities(
    ctx: { sdk: { machineIdentities: Parameters<typeof listMachineIdentities>[0] } },
    offline: boolean,
    identityId?: string
): Promise<MachineIdentityRecord[]> {
    if (identityId) {
        const match = offline
            ? resolveMachineIdentityByIdentityIdOffline(identityId)
            : await resolveMachineIdentityByIdentityId(ctx.sdk.machineIdentities, identityId)
        if (!match) {
            throw new ConnectorError(`Machine identity not found: ${identityId}`)
        }
        return [match]
    }

    return offline ? listMachineIdentitiesOffline() : listMachineIdentities(ctx.sdk.machineIdentities)
}

async function loadSchema(
    ctx: { sdk: { sources: Parameters<typeof getAccountSchema>[0] } },
    offline: boolean,
    sourceId: string,
    cache: Map<string, SchemaPayload | undefined>
): Promise<SchemaPayload | undefined> {
    if (cache.has(sourceId)) {
        return cache.get(sourceId)
    }
    const schema = offline ? getOfflineAccountSchema(sourceId) : await getAccountSchema(ctx.sdk.sources, sourceId)
    cache.set(sourceId, schema)
    return schema
}

async function listUnderlyingAccounts(
    accounts: Parameters<typeof listAccounts>[0],
    identityKey: string
): Promise<UnderlyingAccount[]> {
    const filters = `identityId eq "${escapeODataString(identityKey)}"`
    const collected: UnderlyingAccount[] = []
    let offset = 0

    while (true) {
        const page = await listAccounts(accounts, {
            filters,
            limit: ACCOUNT_PAGE_SIZE,
            offset,
            detailLevel: 'FULL',
        })
        collected.push(...page)
        if (page.length < ACCOUNT_PAGE_SIZE) {
            break
        }
        offset += ACCOUNT_PAGE_SIZE
    }

    return collected
}
