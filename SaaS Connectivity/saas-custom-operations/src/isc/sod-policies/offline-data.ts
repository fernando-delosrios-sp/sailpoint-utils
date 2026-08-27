import { SodPolicySummary } from './types'

export const OFFLINE_SOD_POLICIES: SodPolicySummary[] = [
    {
        id: 'policy-offline-1',
        name: 'AP/AR Separation',
        policyQuery: '@access(id:ent-a) AND @access(id:ent-c)',
        ownerRef: { type: 'IDENTITY', id: 'owner-offline-1', name: 'Policy Owner' },
    },
    {
        id: 'policy-offline-2',
        name: 'Structured Fallback Policy',
        conflictingAccessCriteria: {
            leftCriteria: { criteriaList: [{ id: 'ent-x', type: 'ENTITLEMENT' }] },
            rightCriteria: { criteriaList: [{ id: 'ent-y', type: 'ENTITLEMENT' }] },
        },
        ownerRef: { type: 'IDENTITY', id: 'owner-offline-1', name: 'Policy Owner' },
    },
]

/** Returns offline canned policies for local invoke. */
export function listSodPoliciesOffline(): SodPolicySummary[] {
    return OFFLINE_SOD_POLICIES
}
