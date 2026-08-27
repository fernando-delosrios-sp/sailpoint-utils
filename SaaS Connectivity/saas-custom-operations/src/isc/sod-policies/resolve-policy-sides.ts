import { parsePolicyQuerySides } from './parse-policy-query'
import { PolicySideEntitlements, SodPolicySummary } from './types'

function entitlementIdsFromCriteria(criteria?: { criteriaList?: Array<{ id?: string; type?: string }> }): string[] {
    if (!criteria?.criteriaList) {
        return []
    }

    return criteria.criteriaList
        .filter((item) => Boolean(item.id))
        .filter((item) => !item.type || item.type.toUpperCase() === 'ENTITLEMENT')
        .map((item) => item.id as string)
}

function sidesFromStructuredCriteria(policy: SodPolicySummary): PolicySideEntitlements | null {
    const groupAIds = entitlementIdsFromCriteria(policy.conflictingAccessCriteria?.leftCriteria)
    const groupBIds = entitlementIdsFromCriteria(policy.conflictingAccessCriteria?.rightCriteria)

    if (groupAIds.length === 0 || groupBIds.length === 0) {
        return null
    }

    return { groupAIds, groupBIds }
}

/** Resolves policy side entitlement ids from policyQuery with structured criteria fallback. */
export function resolvePolicySides(policy: SodPolicySummary): PolicySideEntitlements | null {
    if (policy.policyQuery) {
        const parsed = parsePolicyQuerySides(policy.policyQuery)
        if (parsed) {
            return parsed
        }
    }

    return sidesFromStructuredCriteria(policy)
}
