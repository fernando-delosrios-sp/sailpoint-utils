import { SODPoliciesApi } from 'sailpoint-api-client'
import type { SodPolicy } from './types'

/** Lists enforced SoD policies for local entitlement matching. */
export async function listEnforcedSodPolicies(sodPolicies: SODPoliciesApi): Promise<SodPolicy[]> {
    try {
        const response = await sodPolicies.listSodPoliciesV1({
            limit: 250,
            filters: 'state eq "ENFORCED"',
        })
        return (response.data ?? []) as SodPolicy[]
    } catch (error) {
        console.error('[listEnforcedSodPolicies] Error fetching SoD policies:', error)
        return []
    }
}
