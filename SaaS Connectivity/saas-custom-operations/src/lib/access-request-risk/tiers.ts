export type RiskTier = 'High' | 'Medium' | 'Low'
export type DecidingRule = 'effective privilege' | 'Risk metadata'

export interface EntitlementTierResult {
    tier: RiskTier
    rule?: DecidingRule
}

const TIER_RANK: Record<RiskTier, number> = {
    Low: 0,
    Medium: 1,
    High: 2,
}

/** Higher tier wins. */
export function maxTier(left: RiskTier, right: RiskTier): RiskTier {
    return TIER_RANK[left] >= TIER_RANK[right] ? left : right
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

function tierFromToken(value: string): RiskTier | undefined {
    const token = normalizeToken(value)
    if (token === 'critical' || token === 'high') {
        return 'High'
    }
    if (token === 'medium') {
        return 'Medium'
    }
    return undefined
}

function tokensFromMetadataValue(value: unknown): string[] {
    if (typeof value === 'string') {
        return [value]
    }
    const record = asRecord(value)
    if (!record) {
        return []
    }
    const tokens: string[] = []
    if (typeof record.value === 'string') {
        tokens.push(record.value)
    }
    if (typeof record.name === 'string') {
        tokens.push(record.name)
    }
    return tokens
}

/**
 * Maps access-model Risk metadata (`iscRisk`, display name Risk) to a tier.
 * Critical and High are High. Medium is Medium. Anything else, including a missing attribute, is Low.
 */
export function tierFromRiskMetadata(metadata: unknown): RiskTier {
    const attributes = asRecord(metadata)?.attributes
    if (!Array.isArray(attributes)) {
        return 'Low'
    }

    let tier: RiskTier = 'Low'
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
            for (const token of tokensFromMetadataValue(value)) {
                const next = tierFromToken(token)
                if (next) {
                    tier = maxTier(tier, next)
                }
            }
        }
    }
    return tier
}

/**
 * Parses the `considerPrivilege` toggle.
 * Omitted / true / `"true"` → privilegeLevel.effective is scored.
 * false / `"false"` → entitlements use Risk metadata only.
 */
export function parseConsiderPrivilege(value: unknown): boolean {
    if (value === false || value === 0) {
        return false
    }
    if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase()
        if (normalized === 'false' || normalized === '0' || normalized === 'no') {
            return false
        }
    }
    return true
}

/**
 * Returns the entitlement tier and the rule that decided it. Effective privilege gets attribution
 * whenever it produces the final non-Low tier; Risk metadata gets attribution when it produces a
 * higher tier or privilege is ignored. When `considerPrivilege` is false, only Risk metadata is used.
 */
export function tierFromEntitlement(input: {
    effectivePrivilege?: string | null
    metadata: unknown
    considerPrivilege?: boolean
}): EntitlementTierResult {
    const metadataTier = tierFromRiskMetadata(input.metadata)
    if (input.considerPrivilege === false) {
        return metadataTier === 'Low' ? { tier: 'Low' } : { tier: metadataTier, rule: 'Risk metadata' }
    }

    const effective = (input.effectivePrivilege ?? '').trim().toUpperCase()
    const privilegeTier: RiskTier = effective === 'HIGH' ? 'High' : effective === 'MEDIUM' ? 'Medium' : 'Low'
    const tier = maxTier(privilegeTier, metadataTier)

    if (tier === 'Low') {
        return { tier }
    }
    return { tier, rule: privilegeTier === tier ? 'effective privilege' : 'Risk metadata' }
}
