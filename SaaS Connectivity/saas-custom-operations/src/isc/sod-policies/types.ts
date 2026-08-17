/** Minimal SoD policy shape used by access-sod-remediation evaluation. */
export interface SodPolicySummary {
    id: string
    name: string
    state?: 'ENFORCED' | 'NOT_ENFORCED'
    policyQuery?: string
    ownerRef?: {
        type?: string
        id?: string
        name?: string
    }
    conflictingAccessCriteria?: {
        leftCriteria?: {
            criteriaList?: Array<{ id?: string; type?: string }>
        }
        rightCriteria?: {
            criteriaList?: Array<{ id?: string; type?: string }>
        }
    }
}

export interface PolicySideEntitlements {
    groupAIds: string[]
    groupBIds: string[]
}
