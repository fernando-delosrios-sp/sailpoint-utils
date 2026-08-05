import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, OperationSignature } from '../framework'
import { AccessService } from '../services/access.service'
import { SodService } from '../services/sod.service'

export interface CheckSodPendingOperation extends OperationSignature {
    input: {
        identityId?: string
    }
    output: {
        identityId: string
        hasViolations: boolean
        violatedPolicyNames: string[]
    }
}

export const checkSodPendingOperation = customOperation<CheckSodPendingOperation>(async (ctx, input) => {
    const identityId = input.identityId
    if (!identityId) {
        throw new ConnectorError('Missing required input field: identityId')
    }

    const accessService = new AccessService(ctx.sdk)
    const sodService = new SodService(ctx.sdk)

    const [pendingEntitlements, grantedEntitlements, policies] = await Promise.all([
        accessService.getPendingEntitlements(identityId, 'none'),
        accessService.getGrantedEntitlements(identityId),
        sodService.fetchSodPolicies(),
    ])

    const allEntitlementsMap = new Map<string, (typeof pendingEntitlements)[number]>()
    grantedEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
    pendingEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
    const combinedEntitlements = Array.from(allEntitlementsMap.values())

    const localViolations = sodService.checkPoliciesAgainstEntitlements(combinedEntitlements, policies)
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
})
