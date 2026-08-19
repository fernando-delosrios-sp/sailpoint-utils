export interface SodPolicyCriteriaItem {
    type: 'ENTITLEMENT'
    id: string
    name?: string
}

export interface SodPolicyCriteriaSide {
    name?: string
    criteriaList: SodPolicyCriteriaItem[]
}

export interface SodPolicy {
    id: string
    name: string
    conflictingAccessCriteria?: {
        leftCriteria: SodPolicyCriteriaSide
        rightCriteria: SodPolicyCriteriaSide
    } | null
}

export interface DetectedViolation {
    policyId: string
    policyName: string
    matchedLeft: string[]
    matchedRight: string[]
}

/** Minimal SoD policy shape used by access-model-sod-remediation evaluation. */
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
