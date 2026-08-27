import {
    ExpandedAccessItemEntitlements,
    NestedAccessProfileBundle,
} from '../access-model-sod-remediation/expand-access-item-entitlements'
import { AccessItemType, ParsedFormInstance } from './parse-form-instance'

export interface DetachedAccessProfileDetail {
    id: string
    name: string
    offendingEntitlementNames: string[]
}

export interface RemovedEntitlementDetail {
    id: string
    name?: string
}

export interface CorrectionPlan {
    accessItemId: string
    accessItemType: AccessItemType
    removedEntitlementIds: string[]
    detachedAccessProfileIds: string[]
    detachedAccessProfileDetails: DetachedAccessProfileDetail[]
    removedEntitlementDetails: RemovedEntitlementDetail[]
}

function findNestedProfileForEntitlement(
    entitlementId: string,
    nestedProfiles: NestedAccessProfileBundle[]
): NestedAccessProfileBundle | undefined {
    return nestedProfiles.find((profile) => profile.entitlements.some((entitlement) => entitlement.id === entitlementId))
}

function entitlementName(expanded: ExpandedAccessItemEntitlements, entitlementId: string): string | undefined {
    return expanded.entitlements.find((entitlement) => entitlement.id === entitlementId)?.name
}

/** Builds a catalog correction plan from parsed form input and expanded access item entitlements. */
export function buildCorrectionPlan(
    parsed: ParsedFormInstance,
    expanded: ExpandedAccessItemEntitlements
): CorrectionPlan {
    const sideIds = parsed.remediationSide === 'groupA' ? parsed.groupAIds : parsed.groupBIds

    if (parsed.accessItemType === 'ACCESS_PROFILE') {
        const removedEntitlementIds = sideIds.filter((id) => expanded.entitlementIds.has(id))
        return {
            accessItemId: parsed.accessItemId,
            accessItemType: parsed.accessItemType,
            removedEntitlementIds,
            detachedAccessProfileIds: [],
            detachedAccessProfileDetails: [],
            removedEntitlementDetails: removedEntitlementIds.map((id) => ({
                id,
                name: entitlementName(expanded, id),
            })),
        }
    }

    const detachedAccessProfileIds: string[] = []
    const detachedAccessProfileDetails: DetachedAccessProfileDetail[] = []
    const removedEntitlementIds: string[] = []
    const removedEntitlementDetails: RemovedEntitlementDetail[] = []

    for (const entitlementId of sideIds) {
        if (!expanded.entitlementIds.has(entitlementId)) {
            continue
        }

        const nestedProfile = findNestedProfileForEntitlement(entitlementId, expanded.nestedProfiles)
        if (nestedProfile) {
            if (!detachedAccessProfileIds.includes(nestedProfile.id)) {
                detachedAccessProfileIds.push(nestedProfile.id)
                const offendingEntitlementNames = sideIds
                    .filter((id) => nestedProfile.entitlements.some((entitlement) => entitlement.id === id))
                    .map((id) => nestedProfile.entitlements.find((entitlement) => entitlement.id === id)?.name ?? id)
                detachedAccessProfileDetails.push({
                    id: nestedProfile.id,
                    name: nestedProfile.name,
                    offendingEntitlementNames,
                })
            }
            continue
        }

        removedEntitlementIds.push(entitlementId)
        removedEntitlementDetails.push({
            id: entitlementId,
            name: entitlementName(expanded, entitlementId),
        })
    }

    return {
        accessItemId: parsed.accessItemId,
        accessItemType: parsed.accessItemType,
        removedEntitlementIds,
        detachedAccessProfileIds,
        detachedAccessProfileDetails,
        removedEntitlementDetails,
    }
}

/** Returns true when no catalog mutations remain for the selected remediation side. */
export function isCorrectionPlanEmpty(plan: CorrectionPlan): boolean {
    return plan.removedEntitlementIds.length === 0 && plan.detachedAccessProfileIds.length === 0
}
