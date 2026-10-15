import { SearchApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { resolvePolicySides, type SodPolicySummary } from '../sod-policies'

const PAGE_SIZE = 250
const IDENTITIES_INDEX = 'identities' as const

/** Builds an identity search query that matches both sides of a SoD policy. */
export function buildPolicyViolationSearchQuery(policy: SodPolicySummary): string | null {
    const fromPolicy = policy.policyQuery?.trim()
    if (fromPolicy) {
        return fromPolicy
    }

    const sides = resolvePolicySides(policy)
    if (!sides) {
        return null
    }

    const left = sides.groupAIds.map((id) => `id:${id}`).join(' OR ')
    const right = sides.groupBIds.map((id) => `id:${id}`).join(' OR ')
    if (!left || !right) {
        return null
    }
    return `@access(${left}) AND @access(${right})`
}

/**
 * Lists identity ids that currently hold conflicting access for a policy via ISC search.
 * Prefer this over Closed violation records when discovering who is still in violation.
 */
export async function listViolatingIdentityIdsByPolicyQuery(
    search: SearchApi,
    policy: SodPolicySummary
): Promise<string[]> {
    const query = buildPolicyViolationSearchQuery(policy)
    if (!query) {
        logIscDebug('listViolatingIdentityIdsByPolicyQuery skip', {
            policyId: policy.id,
            reason: 'no searchable policy query',
        })
        return []
    }

    const ids: string[] = []
    const seen = new Set<string>()
    let offset = 0

    try {
        while (true) {
            const request = {
                offset,
                limit: PAGE_SIZE,
                search: {
                    indices: [IDENTITIES_INDEX],
                    query: { query },
                    queryResultFilter: { includes: ['id'] },
                },
            }
            logIscDebug('listViolatingIdentityIdsByPolicyQuery searchPostV1', {
                policyId: policy.id,
                offset,
                query,
            })
            const response = await search.searchPostV1(request)
            const page = (response.data ?? []) as Array<{ id?: string }>
            for (const row of page) {
                if (!row.id || seen.has(row.id)) {
                    continue
                }
                seen.add(row.id)
                ids.push(row.id)
            }
            if (page.length < PAGE_SIZE) {
                break
            }
            offset += PAGE_SIZE
        }
        logIscDebug('listViolatingIdentityIdsByPolicyQuery complete', {
            policyId: policy.id,
            count: ids.length,
        })
        return ids
    } catch (error) {
        logIscRequestFailure('listViolatingIdentityIdsByPolicyQuery searchPostV1', error)
        throw toConnectorError(error, `Failed to search violators for policy ${policy.id}`)
    }
}
