import { truncateForIscStorage, ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { DecidingRule, maxTier, RiskTier, tierFromEntitlement, tierFromRiskMetadata } from './tiers'

export type RequestedItemType = 'ROLE' | 'ACCESS_PROFILE' | 'ENTITLEMENT'

export interface RequestedAccessItem {
    id: string
    type: RequestedItemType
    name?: string
}

export interface RoleSnapshot {
    metadata: unknown
    accessProfileIds: string[]
    entitlementIds: string[]
}

export interface AccessProfileSnapshot {
    metadata: unknown
    entitlementIds: string[]
}

export interface EntitlementSnapshot {
    effectivePrivilege?: string | null
    metadata: unknown
}

/** Reads only roles, access profiles, and entitlements. Dimensions are not part of this catalog. */
export interface AccessRiskCatalog {
    getRole(id: string): Promise<RoleSnapshot>
    getAccessProfile(id: string): Promise<AccessProfileSnapshot>
    getEntitlement(id: string): Promise<EntitlementSnapshot>
}

export interface RiskDriver {
    id: string
    type: RequestedItemType
    tier: RiskTier
    rule?: DecidingRule
}

export interface AccessRiskResult {
    tier: RiskTier
    situationSummary: string
    contributingIds: string
}

function normalizeItemType(type: string): RequestedItemType | undefined {
    const normalized = type.trim().toUpperCase()
    if (normalized === 'ROLE' || normalized === 'ACCESS_PROFILE' || normalized === 'ENTITLEMENT') {
        return normalized
    }
    return undefined
}

export function normalizeRequestedItem(item: {
    id?: string
    type?: string
    name?: string
}): RequestedAccessItem | undefined {
    const id = item.id?.trim()
    const type = item.type ? normalizeItemType(item.type) : undefined
    if (!id || !type) {
        return undefined
    }
    const name = item.name?.trim()
    return name ? { id, type, name } : { id, type }
}

function fit(value: string): string {
    return truncateForIscStorage(value, ISC_STRING_ATTRIBUTE_MAX_LENGTH, 'evaluate-access-request-risk')
}

const TYPE_ORDER: RequestedItemType[] = ['ROLE', 'ACCESS_PROFILE', 'ENTITLEMENT']
const TYPE_LABELS: Record<RequestedItemType, [singular: string, plural: string]> = {
    ROLE: ['role', 'roles'],
    ACCESS_PROFILE: ['access profile', 'access profiles'],
    ENTITLEMENT: ['entitlement', 'entitlements'],
}
const RULE_ORDER: DecidingRule[] = ['effective privilege', 'Risk metadata']

function distinctDrivers(drivers: RiskDriver[]): RiskDriver[] {
    return [...new Map(drivers.map((driver) => [`${driver.type}:${driver.id}`, driver])).values()]
}

function countByType(drivers: RiskDriver[], type: RequestedItemType): number {
    return drivers.filter((driver) => driver.type === type).length
}

function typeLabel(type: RequestedItemType, count: number): string {
    const [singular, plural] = TYPE_LABELS[type]
    return count === 1 ? singular : plural
}

function formatTally(drivers: RiskDriver[]): string {
    const parts = TYPE_ORDER.flatMap((type) => {
        const count = countByType(drivers, type)
        return count === 0 ? [] : [`${count} ${typeLabel(type, count)}`]
    })
    return parts.length === 0 ? 'no access objects' : parts.join(', ')
}

/** Builds the human-readable verdict, deciding-rule split, and distinct-object tally. */
function summarize(
    tier: RiskTier,
    drivers: RiskDriver[]
): Pick<AccessRiskResult, 'situationSummary' | 'contributingIds'> {
    const distinct = distinctDrivers(drivers)
    const tally = formatTally(distinct)
    const winning = tier === 'Low' ? [] : distinct.filter((driver) => driver.tier === tier)
    const contributingIds =
        tier === 'Low'
            ? ''
            : fit(
                  drivers
                      .filter((driver) => driver.tier === tier)
                      .map((driver) => driver.id)
                      .join(',')
              )

    if (tier === 'Low') {
        return {
            situationSummary: fit(`Low: nothing scored Medium or High. Evaluated ${tally}.`),
            contributingIds,
        }
    }

    const winningCounts = TYPE_ORDER.flatMap((type) => {
        const winningCount = countByType(winning, type)
        if (winningCount === 0) {
            return []
        }
        const totalCount = countByType(distinct, type)
        return [`${winningCount} of ${totalCount} ${typeLabel(type, totalCount)}`]
    })
    const ruleCounts = RULE_ORDER.flatMap((rule) => {
        const count = winning.filter((driver) => driver.rule === rule).length
        return count === 0 ? [] : [`${count} by ${rule}`]
    })

    return {
        situationSummary: fit(
            `${tier}: ${winningCounts.join(', ')} scored ${tier} (${ruleCounts.join(', ')}). Evaluated ${tally}.`
        ),
        contributingIds,
    }
}

export interface EvaluateAccessRiskOptions {
    /** When false, entitlement scoring ignores privilegeLevel.effective. Defaults to true. */
    considerPrivilege?: boolean
}

/** Highest tier across requested items, their access profiles, and their entitlements. */
export async function evaluateAccessRisk(
    items: RequestedAccessItem[],
    catalog: AccessRiskCatalog,
    options: EvaluateAccessRiskOptions = {}
): Promise<AccessRiskResult> {
    const considerPrivilege = options.considerPrivilege !== false
    const drivers: RiskDriver[] = []
    const entitlementTiers = new Map<string, RiskTier>()
    const profileTiers = new Map<string, RiskTier>()

    const scoreEntitlement = async (id: string): Promise<RiskTier> => {
        const cached = entitlementTiers.get(id)
        if (cached) {
            return cached
        }
        const entitlement = await catalog.getEntitlement(id)
        const result = tierFromEntitlement({
            effectivePrivilege: entitlement.effectivePrivilege,
            metadata: entitlement.metadata,
            considerPrivilege,
        })
        entitlementTiers.set(id, result.tier)
        drivers.push({ id, type: 'ENTITLEMENT', tier: result.tier, rule: result.rule })
        return result.tier
    }

    const scoreAccessProfile = async (id: string): Promise<RiskTier> => {
        const cached = profileTiers.get(id)
        if (cached) {
            return cached
        }
        const profile = await catalog.getAccessProfile(id)
        let tier = tierFromRiskMetadata(profile.metadata)
        drivers.push({
            id,
            type: 'ACCESS_PROFILE',
            tier,
            rule: tier === 'Low' ? undefined : 'Risk metadata',
        })
        for (const entitlementId of profile.entitlementIds) {
            tier = maxTier(tier, await scoreEntitlement(entitlementId))
        }
        profileTiers.set(id, tier)
        return tier
    }

    let tier: RiskTier = 'Low'
    for (const item of items) {
        if (item.type === 'ENTITLEMENT') {
            tier = maxTier(tier, await scoreEntitlement(item.id))
            continue
        }
        if (item.type === 'ACCESS_PROFILE') {
            tier = maxTier(tier, await scoreAccessProfile(item.id))
            continue
        }

        const role = await catalog.getRole(item.id)
        let roleTier = tierFromRiskMetadata(role.metadata)
        drivers.push({
            id: item.id,
            type: 'ROLE',
            tier: roleTier,
            rule: roleTier === 'Low' ? undefined : 'Risk metadata',
        })
        for (const accessProfileId of role.accessProfileIds) {
            roleTier = maxTier(roleTier, await scoreAccessProfile(accessProfileId))
        }
        for (const entitlementId of role.entitlementIds) {
            roleTier = maxTier(roleTier, await scoreEntitlement(entitlementId))
        }
        tier = maxTier(tier, roleTier)
    }

    const summary = summarize(tier, drivers)
    return { tier, ...summary }
}
