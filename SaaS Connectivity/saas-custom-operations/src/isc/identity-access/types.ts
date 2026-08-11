export type AccessPathType = 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'

export interface IdentityAccessItem {
    type: AccessPathType
    id: string
    name: string
    /** Entitlement IDs granted through this access profile or role. */
    grantedEntitlementIds?: string[]
}
