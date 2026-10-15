import { type IscClientConfig, iscGet } from '../http'
import { logIscDebug } from '../debug/log-isc-request'

const PAGE_SIZE = 250

/**
 * Statuses that still mean the identity is in violation (conflicting access remains).
 * Closed / Remediated mean the toxic combination was removed — those are excluded.
 * Title-case API values are normalized before comparison.
 */
const ACTIVE_STATUSES = new Set(['OPEN', 'MITIGATED', 'REOPENED', 'RE-OPENED'])

export interface PolicyViolationIdentity {
    identityId: string
    violationId: string
    status?: string
}

interface ViolationListEntry {
    id?: string
    status?: string
    identity?: { id?: string }
    target?: { id?: string }
}

function isActiveViolation(status: string | undefined): boolean {
    if (!status) {
        return true
    }
    return ACTIVE_STATUSES.has(status.trim().toUpperCase())
}

function identityIdOf(entry: ViolationListEntry): string | undefined {
    return entry.identity?.id ?? entry.target?.id
}

/** Pages GET /violations/v1 for a policy and returns active violating identity ids. */
export async function listViolatingIdentityIdsForPolicy(
    config: IscClientConfig,
    policyId: string
): Promise<string[]> {
    const identities = await listViolationsForPolicy(config, policyId)
    const seen = new Set<string>()
    const ids: string[] = []
    for (const item of identities) {
        if (seen.has(item.identityId)) {
            continue
        }
        seen.add(item.identityId)
        ids.push(item.identityId)
    }
    return ids
}

/**
 * Pages GET /violations/v1 filtered by policyId (experimental).
 * Only Open / Mitigated / Reopened statuses are included; Closed and Remediated are skipped.
 */
export async function listViolationsForPolicy(
    config: IscClientConfig,
    policyId: string
): Promise<PolicyViolationIdentity[]> {
    const results: PolicyViolationIdentity[] = []
    let offset = 0

    while (true) {
        const filter = encodeURIComponent(`policyId eq "${policyId}"`)
        const path = `/violations/v1?filters=${filter}&limit=${PAGE_SIZE}&offset=${offset}`
        logIscDebug('listViolationsForPolicy request', { policyId, offset })
        const raw = await iscGet<ViolationListEntry[] | { items?: ViolationListEntry[] }>(config, path, {
            experimental: true,
        })
        const page = Array.isArray(raw) ? raw : (raw.items ?? [])
        for (const entry of page) {
            const identityId = identityIdOf(entry)
            if (!identityId || !entry.id || !isActiveViolation(entry.status)) {
                continue
            }
            results.push({
                identityId,
                violationId: entry.id,
                ...(entry.status ? { status: entry.status } : {}),
            })
        }
        if (page.length < PAGE_SIZE) {
            break
        }
        offset += PAGE_SIZE
    }

    logIscDebug('listViolationsForPolicy complete', { policyId, count: results.length })
    return results
}
