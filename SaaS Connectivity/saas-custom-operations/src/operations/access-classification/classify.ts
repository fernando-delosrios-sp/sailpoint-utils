export interface PrivilegeLevel {
    effective?: string | null
    direct?: string | null
}

export interface PrivilegedWalkResult {
    privileged: boolean
    examinedCount: number
}

export interface PrivilegedRoleResult {
    privileged: boolean
    examinedAccessProfiles: number
    examinedEntitlements: number
}

export interface SodTagWalkResult {
    tags: Set<string>
    examinedEntitlements: number
}

export interface SodRoleTagWalkResult {
    tags: Set<string>
    examinedAccessProfiles: number
    examinedEntitlements: number
}

function normalizePrivilege(value: string | null | undefined): string {
    return (value ?? '').trim().toUpperCase()
}

/** True when effective (or direct fallback) privilege is MEDIUM or HIGH. */
export function isPrivilegedEntitlement(privilegeLevel: PrivilegeLevel | undefined): boolean {
    if (!privilegeLevel) {
        return false
    }
    const effective = normalizePrivilege(privilegeLevel.effective)
    if (effective === 'MEDIUM' || effective === 'HIGH') {
        return true
    }
    if (effective) {
        return false
    }
    const direct = normalizePrivilege(privilegeLevel.direct)
    return direct === 'MEDIUM' || direct === 'HIGH'
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
    if (value == null || typeof value !== 'object') {
        return undefined
    }
    return value as Record<string, unknown>
}

function normalizeToken(value: string): string {
    return value.trim().toLowerCase()
}

function tokensFromMetadataValue(value: unknown): string[] {
    if (typeof value === 'string') {
        return value.trim() ? [value] : []
    }
    const record = asRecord(value)
    if (!record) {
        return []
    }
    const rawValue = record.value
    if (typeof rawValue === 'string' && rawValue.trim()) {
        return [rawValue]
    }
    const rawName = record.name
    if (typeof rawName === 'string' && rawName.trim()) {
        return [rawName]
    }
    return []
}

/**
 * True when access-model Risk metadata (`iscRisk` / display name Risk) has any non-empty value.
 * Stops at the first non-empty Risk value.
 */
export function hasRiskMetadata(metadata: unknown): boolean {
    const attributes = asRecord(metadata)?.attributes
    if (!Array.isArray(attributes)) {
        return false
    }

    for (const attribute of attributes) {
        const record = asRecord(attribute)
        if (!record) {
            continue
        }
        const key = typeof record.key === 'string' ? normalizeToken(record.key) : ''
        const name = typeof record.name === 'string' ? normalizeToken(record.name) : ''
        if (key !== 'iscrisk' && name !== 'risk') {
            continue
        }
        const values = Array.isArray(record.values) ? record.values : []
        for (const value of values) {
            if (tokensFromMetadataValue(value).length > 0) {
                return true
            }
        }
    }
    return false
}

/** Privileged when any entitlement id is in the privileged set; stops at the first hit. */
export function isPrivilegedAccessProfile(
    entitlementIds: readonly string[],
    privilegedEntitlementIds: ReadonlySet<string>
): PrivilegedWalkResult {
    let examinedCount = 0
    for (const id of entitlementIds) {
        examinedCount += 1
        if (privilegedEntitlementIds.has(id)) {
            return { privileged: true, examinedCount }
        }
    }
    return { privileged: false, examinedCount }
}

/**
 * Privileged when any access profile is already privileged (stop at first),
 * otherwise when any direct entitlement is privileged (stop at first).
 */
export function isPrivilegedRole(
    accessProfileIds: readonly string[],
    entitlementIds: readonly string[],
    privilegedAccessProfileIds: ReadonlySet<string>,
    privilegedEntitlementIds: ReadonlySet<string>
): PrivilegedRoleResult {
    let examinedAccessProfiles = 0
    for (const id of accessProfileIds) {
        examinedAccessProfiles += 1
        if (privilegedAccessProfileIds.has(id)) {
            return { privileged: true, examinedAccessProfiles, examinedEntitlements: 0 }
        }
    }

    let examinedEntitlements = 0
    for (const id of entitlementIds) {
        examinedEntitlements += 1
        if (privilegedEntitlementIds.has(id)) {
            return { privileged: true, examinedAccessProfiles, examinedEntitlements }
        }
    }
    return { privileged: false, examinedAccessProfiles, examinedEntitlements }
}

/**
 * Collects SOD tags from member entitlements. Once a tag is acquired it is not sought again.
 * Entitlements with no pending tags are still counted as examined when visited before all tags are known.
 */
export function collectSodTagsForAccessProfile(
    entitlementIds: readonly string[],
    tagsByEntitlement: ReadonlyMap<string, readonly string[]>
): SodTagWalkResult {
    const tags = new Set<string>()
    let examinedEntitlements = 0

    for (const id of entitlementIds) {
        const entitlementTags = tagsByEntitlement.get(id) ?? []
        examinedEntitlements += 1
        for (const tag of entitlementTags) {
            tags.add(tag)
        }
        if (remainingOnlyKnownTags(entitlementIds, examinedEntitlements, tagsByEntitlement, tags)) {
            break
        }
    }

    return { tags, examinedEntitlements }
}

function remainingOnlyKnownTags(
    entitlementIds: readonly string[],
    examinedCount: number,
    tagsByEntitlement: ReadonlyMap<string, readonly string[]>,
    known: ReadonlySet<string>
): boolean {
    for (let i = examinedCount; i < entitlementIds.length; i++) {
        const entitlementTags = tagsByEntitlement.get(entitlementIds[i]) ?? []
        for (const tag of entitlementTags) {
            if (!known.has(tag)) {
                return false
            }
        }
    }
    return true
}

/**
 * Collects SOD tags from access profiles first (stop looking for a tag once acquired),
 * then from direct entitlements for any still-missing tags.
 */
export function collectSodTagsForRole(
    accessProfileIds: readonly string[],
    entitlementIds: readonly string[],
    tagsByAccessProfile: ReadonlyMap<string, readonly string[]>,
    tagsByEntitlement: ReadonlyMap<string, readonly string[]>
): SodRoleTagWalkResult {
    const tags = new Set<string>()
    let examinedAccessProfiles = 0

    for (const id of accessProfileIds) {
        const profileTags = tagsByAccessProfile.get(id) ?? []
        examinedAccessProfiles += 1
        for (const tag of profileTags) {
            tags.add(tag)
        }
        if (remainingOnlyKnownTags(accessProfileIds, examinedAccessProfiles, tagsByAccessProfile, tags)) {
            break
        }
    }

    let examinedEntitlements = 0
    for (const id of entitlementIds) {
        const entitlementTags = tagsByEntitlement.get(id) ?? []
        examinedEntitlements += 1
        for (const tag of entitlementTags) {
            tags.add(tag)
        }
        if (remainingOnlyKnownTags(entitlementIds, examinedEntitlements, tagsByEntitlement, tags)) {
            break
        }
    }

    return { tags, examinedAccessProfiles, examinedEntitlements }
}
