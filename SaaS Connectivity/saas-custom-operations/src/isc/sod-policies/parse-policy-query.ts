import { PolicySideEntitlements } from './types'

const ACCESS_ID_PATTERN = /id:([^)\s]+)/gi

function extractEntitlementIdsFromAccessClause(clause: string): string[] {
    const ids: string[] = []
    const seen = new Set<string>()
    let match: RegExpExecArray | null

    ACCESS_ID_PATTERN.lastIndex = 0
    while ((match = ACCESS_ID_PATTERN.exec(clause)) !== null) {
        const id = match[1]
        if (!seen.has(id)) {
            seen.add(id)
            ids.push(id)
        }
    }

    return ids
}

/** Parses policyQuery into group A and group B entitlement id sets. Top-level AND separates sides. */
export function parsePolicyQuerySides(policyQuery: string): PolicySideEntitlements | null {
    const trimmed = policyQuery.trim()
    if (!trimmed) {
        return null
    }

    const sideClauses = trimmed.split(/\s+AND\s+/i)
    if (sideClauses.length !== 2) {
        return null
    }

    const groupAIds = extractEntitlementIdsFromAccessClause(sideClauses[0])
    const groupBIds = extractEntitlementIdsFromAccessClause(sideClauses[1])

    if (groupAIds.length === 0 || groupBIds.length === 0) {
        return null
    }

    return { groupAIds, groupBIds }
}
