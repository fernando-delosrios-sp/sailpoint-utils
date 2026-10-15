import type { TaggedObjectRef, TaggedObjectType } from '../../isc/tagged-objects'
import type { SodPolicySummary } from '../../isc/sod-policies'
import { resolvePolicySides } from '../../isc/sod-policies'
import {
    collectSodTagsForAccessProfile,
    collectSodTagsForRole,
    hasRiskMetadata,
    isPrivilegedAccessProfile,
    isPrivilegedEntitlement,
    isPrivilegedRole,
} from './classify'
import { PRIVILEGED_TAG, RISK_TAG } from './constants'
import type { AccessProfileCatalogItem, EntitlementCatalogItem, RoleCatalogItem } from './catalog'

export type DesiredTagMap = Map<string, Set<string>>

function objectKey(type: TaggedObjectType, id: string): string {
    return `${type}:${id}`
}

export function parseObjectKey(key: string): TaggedObjectRef | undefined {
    const colon = key.indexOf(':')
    if (colon <= 0) {
        return undefined
    }
    return {
        type: key.slice(0, colon) as TaggedObjectType,
        id: key.slice(colon + 1),
    }
}

function addDesired(desired: DesiredTagMap, tag: string, type: TaggedObjectType, id: string): void {
    let holders = desired.get(tag)
    if (!holders) {
        holders = new Set()
        desired.set(tag, holders)
    }
    holders.add(objectKey(type, id))
}

/** Builds SOD tags-by-entitlement from enforced policies that carry tags. */
export function buildSodTagsByEntitlement(policies: readonly SodPolicySummary[]): {
    tagsByEntitlement: Map<string, string[]>
    managedSodTags: Set<string>
    policiesWithTags: SodPolicySummary[]
} {
    const tagSets = new Map<string, Set<string>>()
    const managedSodTags = new Set<string>()
    const policiesWithTags: SodPolicySummary[] = []

    for (const policy of policies) {
        if (policy.state && policy.state !== 'ENFORCED') {
            continue
        }
        const tags = (policy.tags ?? []).map((tag) => tag.trim()).filter(Boolean)
        if (tags.length === 0) {
            continue
        }
        const sides = resolvePolicySides(policy)
        if (!sides) {
            continue
        }
        policiesWithTags.push(policy)
        for (const tag of tags) {
            managedSodTags.add(tag)
        }
        for (const entitlementId of [...sides.groupAIds, ...sides.groupBIds]) {
            let set = tagSets.get(entitlementId)
            if (!set) {
                set = new Set()
                tagSets.set(entitlementId, set)
            }
            for (const tag of tags) {
                set.add(tag)
            }
        }
    }

    const tagsByEntitlement = new Map<string, string[]>()
    for (const [id, set] of tagSets) {
        tagsByEntitlement.set(id, [...set])
    }
    return { tagsByEntitlement, managedSodTags, policiesWithTags }
}

export interface ClassificationCatalog {
    entitlements: readonly EntitlementCatalogItem[]
    accessProfiles: readonly AccessProfileCatalogItem[]
    roles: readonly RoleCatalogItem[]
}

export interface DesiredClassification {
    desired: DesiredTagMap
    managedTags: Set<string>
    privilegedEntitlementIds: Set<string>
    privilegedAccessProfileIds: Set<string>
    policiesWithTags: SodPolicySummary[]
    tagsByEntitlement: Map<string, string[]>
    tagsByAccessProfile: Map<string, string[]>
    entitlementsScanned: number
    accessProfilesScanned: number
    rolesScanned: number
}

/** Classifies the access catalog into a desired tag membership map. */
export function buildDesiredClassification(
    catalog: ClassificationCatalog,
    policies: readonly SodPolicySummary[]
): DesiredClassification {
    const desired: DesiredTagMap = new Map()
    const managedTags = new Set<string>([PRIVILEGED_TAG, RISK_TAG])
    const privilegedEntitlementIds = new Set<string>()
    const privilegedAccessProfileIds = new Set<string>()

    const { tagsByEntitlement, managedSodTags, policiesWithTags } = buildSodTagsByEntitlement(policies)
    for (const tag of managedSodTags) {
        managedTags.add(tag)
    }

    for (const entitlement of catalog.entitlements) {
        if (isPrivilegedEntitlement(entitlement.privilegeLevel)) {
            privilegedEntitlementIds.add(entitlement.id)
            addDesired(desired, PRIVILEGED_TAG, 'ENTITLEMENT', entitlement.id)
        }
        if (hasRiskMetadata(entitlement.metadata)) {
            addDesired(desired, RISK_TAG, 'ENTITLEMENT', entitlement.id)
        }
        for (const tag of tagsByEntitlement.get(entitlement.id) ?? []) {
            addDesired(desired, tag, 'ENTITLEMENT', entitlement.id)
        }
    }

    const tagsByAccessProfile = new Map<string, string[]>()
    for (const accessProfile of catalog.accessProfiles) {
        if (isPrivilegedAccessProfile(accessProfile.entitlementIds, privilegedEntitlementIds).privileged) {
            privilegedAccessProfileIds.add(accessProfile.id)
            addDesired(desired, PRIVILEGED_TAG, 'ACCESS_PROFILE', accessProfile.id)
        }
        if (hasRiskMetadata(accessProfile.metadata)) {
            addDesired(desired, RISK_TAG, 'ACCESS_PROFILE', accessProfile.id)
        }
        const sod = collectSodTagsForAccessProfile(accessProfile.entitlementIds, tagsByEntitlement)
        if (sod.tags.size > 0) {
            tagsByAccessProfile.set(accessProfile.id, [...sod.tags])
            for (const tag of sod.tags) {
                addDesired(desired, tag, 'ACCESS_PROFILE', accessProfile.id)
            }
        }
    }

    for (const role of catalog.roles) {
        if (
            isPrivilegedRole(
                role.accessProfileIds,
                role.entitlementIds,
                privilegedAccessProfileIds,
                privilegedEntitlementIds
            ).privileged
        ) {
            addDesired(desired, PRIVILEGED_TAG, 'ROLE', role.id)
        }
        if (hasRiskMetadata(role.metadata)) {
            addDesired(desired, RISK_TAG, 'ROLE', role.id)
        }
        const sod = collectSodTagsForRole(
            role.accessProfileIds,
            role.entitlementIds,
            tagsByAccessProfile,
            tagsByEntitlement
        )
        for (const tag of sod.tags) {
            addDesired(desired, tag, 'ROLE', role.id)
        }
    }

    return {
        desired,
        managedTags,
        privilegedEntitlementIds,
        privilegedAccessProfileIds,
        policiesWithTags,
        tagsByEntitlement,
        tagsByAccessProfile,
        entitlementsScanned: catalog.entitlements.length,
        accessProfilesScanned: catalog.accessProfiles.length,
        rolesScanned: catalog.roles.length,
    }
}

/** Adds identity holders for SOD tags from violating identity ids per policy. */
export function addViolatingIdentities(
    desired: DesiredTagMap,
    policyTags: readonly string[],
    identityIds: readonly string[]
): number {
    let added = 0
    for (const identityId of identityIds) {
        for (const tag of policyTags) {
            const before = desired.get(tag)?.size ?? 0
            addDesired(desired, tag, 'IDENTITY', identityId)
            if ((desired.get(tag)?.size ?? 0) > before) {
                added += 1
            }
        }
    }
    return identityIds.length
}
