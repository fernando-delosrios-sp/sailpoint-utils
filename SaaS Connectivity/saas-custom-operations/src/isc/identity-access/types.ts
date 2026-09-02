import type { IdentityHistoryApi, RolesApi } from 'sailpoint-api-client'

export type AccessPathType = 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'

export interface IdentityAccessSdk {
    identityHistory: IdentityHistoryApi
    roles: RolesApi
}

export interface IdentityAccessItem {
    type: AccessPathType
    id: string
    name: string
    /** Entitlement IDs granted through this role (or other parent access item in fixtures). */
    grantedEntitlementIds?: string[]
}

