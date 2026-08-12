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
