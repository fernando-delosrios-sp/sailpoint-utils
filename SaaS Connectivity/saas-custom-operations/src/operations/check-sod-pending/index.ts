import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, OperationSignature } from '../../framework'
import {
    getGrantedEntitlements,
    getPendingEntitlements,
} from '../../isc/access-requests/entitlement-aggregation'
import { checkPoliciesAgainstEntitlements } from '../../isc/sod-policies/check-policies-against-entitlements'
import { listEnforcedSodPolicies } from '../../isc/sod-policies/list-enforced-policies'
import { checkSodPendingOperationSchema } from './index.schema'

export interface CheckSodPendingOperation extends OperationSignature {
    command: 'custom:check-sod-pending'
    input: {
        identityId?: string
    }
    output: {
        identityId: string
        hasViolations: boolean
        violatedPolicyNames: string[]
    }
}

/** Checks pending and granted entitlements against enforced SoD policies (local matcher). */
export const checkSodPendingOperation = customOperation<CheckSodPendingOperation>(
    async (ctx, input) => {
        const identityId = input.identityId
        if (!identityId) {
            throw new ConnectorError('Missing required input field: identityId')
        }

        const [pendingEntitlements, grantedEntitlements, policies] = await Promise.all([
            getPendingEntitlements(ctx.sdk, identityId, 'none'),
            getGrantedEntitlements(ctx.sdk, identityId),
            listEnforcedSodPolicies(ctx.sdk.sodPolicies),
        ])

        const allEntitlementsMap = new Map<string, (typeof pendingEntitlements)[number]>()
        grantedEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
        pendingEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
        const combinedEntitlements = Array.from(allEntitlementsMap.values())

        const localViolations = checkPoliciesAgainstEntitlements(combinedEntitlements, policies)
        const violatedPolicyNamesSet = new Set<string>()
        localViolations.forEach((violation) => violatedPolicyNamesSet.add(violation.policyName))
        const violatedPolicyNames = Array.from(violatedPolicyNamesSet)

        ctx.res.send({
            status: 'success',
            identityId,
            hasViolations: localViolations.length > 0,
            violatedPolicyNames,
            counts: {
                pendingEntitlements: pendingEntitlements.length,
                grantedEntitlements: grantedEntitlements.length,
                combinedTotal: combinedEntitlements.length,
            },
        })
    },
    { operationSchema: checkSodPendingOperationSchema }
)
