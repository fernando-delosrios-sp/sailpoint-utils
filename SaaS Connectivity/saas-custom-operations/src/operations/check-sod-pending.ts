import { ConnectorError } from '@sailpoint/connector-sdk'
import { withCustomOperation } from '../framework'
import { AccessService } from '../services/access.service'
import { SodService } from '../services/sod.service'

interface CheckSodPendingInput extends Record<string, unknown> {
    identityId?: string
}

export const checkSodPendingOperation = withCustomOperation<CheckSodPendingInput>(async (ctx, input) => {
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
    const violatedPolicyNames = Array.from(violatedPolicyNamesSet).join(', ') || 'N/A'

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
