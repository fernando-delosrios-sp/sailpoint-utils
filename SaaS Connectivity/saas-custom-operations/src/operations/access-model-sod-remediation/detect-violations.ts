import { SodPolicySummary, resolvePolicySides } from '../../isc/sod-policies'
import { CatalogAccessItem } from '../../isc/roles/list-enabled-roles'
import { ExpandedAccessItemEntitlements } from './expand-access-item-entitlements'

export interface AccessItemViolation {
    accessItem: CatalogAccessItem
    policy: SodPolicySummary
    groupAIds: string[]
    groupBIds: string[]
}

function intersect(sideIds: string[], itemEntitlementIds: Set<string>): string[] {
    return sideIds.filter((id) => itemEntitlementIds.has(id))
}

/** Detects policy violations for one access item against all policies. */
export function detectAccessItemViolations(
    accessItem: CatalogAccessItem,
    expanded: ExpandedAccessItemEntitlements,
    policies: SodPolicySummary[]
): AccessItemViolation[] {
    const violations: AccessItemViolation[] = []

    for (const policy of policies) {
        const sides = resolvePolicySides(policy)
        if (!sides) {
            continue
        }

        const groupAIds = intersect(sides.groupAIds, expanded.entitlementIds)
        const groupBIds = intersect(sides.groupBIds, expanded.entitlementIds)

        if (groupAIds.length > 0 && groupBIds.length > 0) {
            violations.push({ accessItem, policy, groupAIds, groupBIds })
        }
    }

    return violations
}
