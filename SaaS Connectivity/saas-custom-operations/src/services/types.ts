export interface SourceRef {
    id: string
    name?: string
    type?: string
}

export interface EntitlementRef {
    type: 'ENTITLEMENT'
    id: string
    name?: string
    source?: SourceRef
}

export interface AccessRef {
    type: 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'
    id: string
    name?: string
    source?: SourceRef
}

export interface AccessProfileRef {
    id: string
    name?: string
    type: 'ACCESS_PROFILE'
    entitlements?: EntitlementRef[]
}

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

export interface GetAccessRequestStatus {
    id?: string
    name?: string
    type?: 'ACCESS_PROFILE' | 'ENTITLEMENT' | 'ROLE'
    accessRequestId?: string
    requestedFor?: { id: string; name?: string; type?: string }
    sodViolationContext?: {
        violationCheckResult?: {
            violatedPolicies?: Array<{ name?: string }> | null
        }
    }
    preApprovalTriggerDetails?: {
        comment?: string
    }
    [key: string]: unknown
}

export interface AccessRequestStatusPayload {
    getAccessRequestStatus?: GetAccessRequestStatus | null
    getXdrData?: XdrData | null
}

export interface XdrData {
    score?: number
    [key: string]: unknown
}

export interface RoleDetail {
    id: string
    name?: string
    accessProfiles?: AccessProfileRef[]
}

export interface EntitlementDetail {
    id: string
    name?: string
    source?: SourceRef
}

export type RequestedItemType = 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'

export type EmailRoute = 'manager' | 'manager-owner' | 'manager-owner-bcc' | 'failure'

export type OutputProfile = 'approval-email' | 'ets-comment'

export interface AccessRequestAnalytics {
    iscRiskName: string
    xdrScore: string
    sodPrediction: string
    violatedPolicyNames: string
    recommendationsDecision: string
    recommendationsInterpretations: string
    accessRequestStatus: GetAccessRequestStatus
    xdrData: XdrData | null
}

export interface ApprovalEmailContext {
    managerRefName: string
    displayName: string
    accessRequestId: string
    requestedItemName: string
}
