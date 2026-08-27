import { SODPoliciesApi } from 'sailpoint-api-client'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { toConnectorError } from '../../framework/connector-error'
import { matchesClientStateFilter, resolveSodPolicyListFilters } from './policy-list-filter'
import { SodPolicySummary } from './types'

const POLICY_PAGE_SIZE = 250

function mapPolicy(raw: {
    id?: string
    name?: string
    state?: SodPolicySummary['state']
    policyQuery?: string
    ownerRef?: SodPolicySummary['ownerRef']
    conflictingAccessCriteria?: SodPolicySummary['conflictingAccessCriteria']
}): SodPolicySummary | undefined {
    if (!raw.id || !raw.name) {
        return undefined
    }

    return {
        id: raw.id,
        name: raw.name,
        state: raw.state,
        policyQuery: raw.policyQuery,
        ownerRef: raw.ownerRef,
        conflictingAccessCriteria: raw.conflictingAccessCriteria,
    }
}

/** Lists SoD policies with optional ISC filter, paginating through all results. */
export async function listSodPolicies(sodPolicies: SODPoliciesApi, filters?: string): Promise<SodPolicySummary[]> {
    const { apiFilters, clientState } = resolveSodPolicyListFilters(filters)
    const policies: SodPolicySummary[] = []
    let offset = 0

    logIscDebug('listSodPolicies start', {
        requestedFilters: filters,
        apiFilters: apiFilters ?? null,
        clientState: clientState ?? null,
    })

    try {
        while (true) {
            const request = {
                offset,
                limit: POLICY_PAGE_SIZE,
                ...(apiFilters ? { filters: apiFilters } : {}),
            }
            logIscDebug('listSodPolicies listSodPoliciesV1 request', request)

            const response = await sodPolicies.listSodPoliciesV1(request)
            const page = response.data ?? []
            logIscDebug('listSodPolicies listSodPoliciesV1 response', {
                offset,
                pageSize: page.length,
                totalCollected: policies.length,
            })

            for (const raw of page) {
                const mapped = mapPolicy(raw)
                if (mapped && matchesClientStateFilter(mapped.state, clientState)) {
                    policies.push(mapped)
                }
            }

            if (page.length < POLICY_PAGE_SIZE) {
                break
            }

            offset += POLICY_PAGE_SIZE
        }

        logIscDebug('listSodPolicies complete', { count: policies.length, clientState: clientState ?? null })
        return policies
    } catch (error) {
        logIscRequestFailure('listSodPolicies listSodPoliciesV1', error)
        throw toConnectorError(error, 'Failed to list SoD policies')
    }
}
