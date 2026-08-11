import type { AccessProfilesApi, IdentityHistoryApi, RolesApi } from 'sailpoint-api-client'

export type AccessPathType = 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'

export interface IdentityAccessSdk {
    identityHistory: IdentityHistoryApi
    accessProfiles: AccessProfilesApi
    roles: RolesApi
}

export interface IdentityAccessItem {
    type: AccessPathType
    id: string
    name: string
    /** Entitlement IDs granted through this access profile or role. */
    grantedEntitlementIds?: string[]
}

