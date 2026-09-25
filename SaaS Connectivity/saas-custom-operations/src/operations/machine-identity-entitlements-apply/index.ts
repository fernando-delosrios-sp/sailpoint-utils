import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, isOfflineContext, OperationSignature } from '../../framework'
import {
    getMachineIdentity,
    patchUserEntitlements,
    unionUserEntitlements,
    UserEntitlementRef,
} from '../../isc/machine-identities'
import { machineIdentityEntitlementsApplyOperationSchema } from './index.schema'
import { getMachineIdentityOffline } from './offline-data'

export interface MachineIdentityEntitlementsApplyOperation extends OperationSignature {
    command: 'custom:machine-identity-entitlements-apply'
    input: {
        machineIdentityId: string
        entitlementIds: string[]
        entitlementSourceIds: string[]
    }
    output: {
        'machine-identity-entitlements-apply:machine-identity-id': string
        'machine-identity-entitlements-apply:status': string
        'machine-identity-entitlements-apply:added-entitlement-ids': string[]
    }
    response: {
        addedCount?: number
        totalCount?: number
    }
}

/** Parses the trigger-account string arrays into entitlement refs, rejecting mismatched lengths. */
export function toUserEntitlementRefs(entitlementIds: unknown, entitlementSourceIds: unknown): UserEntitlementRef[] {
    const ids = toStringArray(entitlementIds)
    const sourceIds = toStringArray(entitlementSourceIds)
    if (ids.length !== sourceIds.length) {
        throw new ConnectorError(
            `entitlementIds and entitlementSourceIds must be the same length (got ${ids.length} and ${sourceIds.length})`
        )
    }
    return ids.map((entitlementId, index) => ({ sourceId: sourceIds[index], entitlementId }))
}

function toStringArray(value: unknown): string[] {
    const raw = value === undefined || value === null ? [] : Array.isArray(value) ? value : [value]
    return raw.map((entry) => String(entry).trim()).filter((entry) => entry.length > 0)
}

/** Unions the scanned entitlements onto a machine identity's userEntitlements. */
export const machineIdentityEntitlementsApplyOperation = customOperation<MachineIdentityEntitlementsApplyOperation>(
    async (ctx, input) => {
        const machineIdentityId = input.machineIdentityId?.trim()
        if (!machineIdentityId) {
            throw new ConnectorError('Missing required input field: machineIdentityId')
        }

        const offline = isOfflineContext(ctx)
        const additions = toUserEntitlementRefs(input.entitlementIds, input.entitlementSourceIds)
        const identity = offline
            ? getMachineIdentityOffline(machineIdentityId)
            : await getMachineIdentity(ctx.sdk.machineIdentities, machineIdentityId)
        if (!identity) {
            throw new ConnectorError(`Machine identity not found: ${machineIdentityId}`)
        }

        const union = unionUserEntitlements(identity.userEntitlements, additions)
        const addedCount = union.length - identity.userEntitlements.length
        const addedIds = union.slice(identity.userEntitlements.length).map((entitlement) => entitlement.entitlementId)

        if (addedCount > 0 && !offline) {
            await patchUserEntitlements(ctx.sdk.machineIdentities, machineIdentityId, union)
        }

        await ctx.persist(`${ctx.requestId}:${machineIdentityId}`, {
            'machine-identity-entitlements-apply:machine-identity-id': machineIdentityId,
            'machine-identity-entitlements-apply:status': addedCount > 0 ? 'applied' : 'skipped-already-present',
            'machine-identity-entitlements-apply:added-entitlement-ids': addedIds,
        })

        ctx.respond({ addedCount, totalCount: union.length })
    },
    { operationSchema: machineIdentityEntitlementsApplyOperationSchema }
)
