export interface UserEntitlementRef {
    sourceId: string
    entitlementId: string
}

export interface MachineIdentityRecord {
    id: string
    cisIdentityId?: string
    userEntitlements: UserEntitlementRef[]
}
