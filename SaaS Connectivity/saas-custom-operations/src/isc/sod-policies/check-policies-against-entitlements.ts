import type { EntitlementRef } from '../access-requests/entitlement-types'
import type { DetectedViolation, SodPolicy } from './types'

/** Checks entitlements against enforced SoD policies using local criteria matching. */
export function checkPoliciesAgainstEntitlements(
    entitlements: EntitlementRef[],
    policies: SodPolicy[]
): DetectedViolation[] {
    const violations: DetectedViolation[] = []
    const entitlementIds = new Set(entitlements.map((entry) => entry.id))

    for (const policy of policies) {
        const criteria = policy.conflictingAccessCriteria
        if (!criteria) {
            continue
        }

        const leftIds = criteria.leftCriteria.criteriaList.map((entry) => entry.id)
        const rightIds = criteria.rightCriteria.criteriaList.map((entry) => entry.id)
        const matchedLeft = leftIds.filter((id) => entitlementIds.has(id))
        const matchedRight = rightIds.filter((id) => entitlementIds.has(id))

        if (matchedLeft.length > 0 && matchedRight.length > 0) {
            violations.push({
                policyId: policy.id,
                policyName: policy.name,
                matchedLeft,
                matchedRight,
            })
        }
    }

    return violations
}
