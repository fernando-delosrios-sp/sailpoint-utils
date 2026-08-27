import { SODPoliciesApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { SodPolicySummary } from './types'

/** Fetches a single SoD policy by id. */
export async function getSodPolicy(sodPolicies: SODPoliciesApi, policyId: string): Promise<SodPolicySummary> {
    try {
        const response = await sodPolicies.getSodPolicyV1({ id: policyId })
        const raw = response.data
        if (!raw?.id || !raw.name) {
            throw new Error(`Policy ${policyId} response missing id or name`)
        }

        return {
            id: raw.id,
            name: raw.name,
            policyQuery: raw.policyQuery,
            ownerRef: raw.ownerRef,
            conflictingAccessCriteria: raw.conflictingAccessCriteria,
        }
    } catch (error) {
        throw toConnectorError(error, `Failed to get SoD policy ${policyId}`)
    }
}
