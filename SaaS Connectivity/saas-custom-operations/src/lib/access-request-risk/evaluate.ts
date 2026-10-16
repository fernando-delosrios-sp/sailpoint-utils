import { truncateForIscStorage, ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { DEFAULT_ISC_CONCURRENCY, mapWithConcurrency } from '../../framework/concurrency'
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
        tier === 'Low' ? '' : fit(winning.map((driver) => driver.id).join(','))

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
    /** Max concurrent nested catalog reads. Defaults to {@link DEFAULT_ISC_CONCURRENCY}. */
    concurrency?: number
}

interface ScoredEntitlement {
    tier: RiskTier
    driver: RiskDriver
}

interface ScoredAccessProfile {
    tier: RiskTier
    drivers: RiskDriver[]
}

interface ScoredItem {
    tier: RiskTier
    drivers: RiskDriver[]
}

/** Highest tier across requested items, their access profiles, and their entitlements. */
export async function evaluateAccessRisk(
    items: RequestedAccessItem[],
    catalog: AccessRiskCatalog,
    options: EvaluateAccessRiskOptions = {}
): Promise<AccessRiskResult> {
    const considerPrivilege = options.considerPrivilege !== false
    const concurrency = options.concurrency ?? DEFAULT_ISC_CONCURRENCY
    const entitlementScores = new Map<string, Promise<ScoredEntitlement>>()
    const profileScores = new Map<string, Promise<ScoredAccessProfile>>()

    const scoreEntitlement = (id: string): Promise<ScoredEntitlement> => {
        const cached = entitlementScores.get(id)
        if (cached) {
            return cached
        }
        const pending = (async (): Promise<ScoredEntitlement> => {
            const entitlement = await catalog.getEntitlement(id)
            const result = tierFromEntitlement({
                effectivePrivilege: entitlement.effectivePrivilege,
                metadata: entitlement.metadata,
                considerPrivilege,
            })
            return {
                tier: result.tier,
                driver: { id, type: 'ENTITLEMENT', tier: result.tier, rule: result.rule },
            }
        })().catch((error) => {
            entitlementScores.delete(id)
            throw error
        })
        entitlementScores.set(id, pending)
        return pending
    }

    const scoreAccessProfile = (id: string): Promise<ScoredAccessProfile> => {
        const cached = profileScores.get(id)
        if (cached) {
            return cached
        }
        const pending = (async (): Promise<ScoredAccessProfile> => {
            const profile = await catalog.getAccessProfile(id)
            const metadataTier = tierFromRiskMetadata(profile.metadata)
            const profileDriver: RiskDriver = {
                id,
                type: 'ACCESS_PROFILE',
                tier: metadataTier,
                rule: metadataTier === 'Low' ? undefined : 'Risk metadata',
            }
            const entitlementResults = await mapWithConcurrency(
                profile.entitlementIds,
                concurrency,
                (entitlementId) => scoreEntitlement(entitlementId)
            )
            let tier = metadataTier
            const drivers: RiskDriver[] = [profileDriver]
            for (const entitlement of entitlementResults) {
                tier = maxTier(tier, entitlement.tier)
                drivers.push(entitlement.driver)
            }
            return { tier, drivers }
        })().catch((error) => {
            profileScores.delete(id)
            throw error
        })
        profileScores.set(id, pending)
        return pending
    }

    const scoreItem = async (item: RequestedAccessItem): Promise<ScoredItem> => {
        if (item.type === 'ENTITLEMENT') {
            const scored = await scoreEntitlement(item.id)
            return { tier: scored.tier, drivers: [scored.driver] }
        }
        if (item.type === 'ACCESS_PROFILE') {
            return scoreAccessProfile(item.id)
        }

        const role = await catalog.getRole(item.id)
        const roleMetadataTier = tierFromRiskMetadata(role.metadata)
        const roleDriver: RiskDriver = {
            id: item.id,
            type: 'ROLE',
            tier: roleMetadataTier,
            rule: roleMetadataTier === 'Low' ? undefined : 'Risk metadata',
        }
        const [profileResults, entitlementResults] = await Promise.all([
            mapWithConcurrency(role.accessProfileIds, concurrency, (accessProfileId) =>
                scoreAccessProfile(accessProfileId)
            ),
            mapWithConcurrency(role.entitlementIds, concurrency, (entitlementId) => scoreEntitlement(entitlementId)),
        ])

        let roleTier = roleMetadataTier
        const drivers: RiskDriver[] = [roleDriver]
        for (const profile of profileResults) {
            roleTier = maxTier(roleTier, profile.tier)
            drivers.push(...profile.drivers)
        }
        for (const entitlement of entitlementResults) {
            roleTier = maxTier(roleTier, entitlement.tier)
            drivers.push(entitlement.driver)
        }
        return { tier: roleTier, drivers }
    }

    const scoredItems = await mapWithConcurrency(items, concurrency, (item) => scoreItem(item))
    let tier: RiskTier = 'Low'
    const drivers: RiskDriver[] = []
    for (const scored of scoredItems) {
        tier = maxTier(tier, scored.tier)
        drivers.push(...scored.drivers)
    }

    const summary = summarize(tier, drivers)
    return { tier, ...summary }
}
