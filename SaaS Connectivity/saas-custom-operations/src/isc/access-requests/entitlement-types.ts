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

export interface AccessProfileRef {
    id: string
    name?: string
    type: 'ACCESS_PROFILE'
    entitlements?: EntitlementRef[]
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

export interface EntitlementDetail {
    id: string
    name?: string
    source?: SourceRef
}

export interface RoleDetail {
    id: string
    name?: string
    accessProfiles?: AccessProfileRef[]
}

export type RequestedItemType = 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'
