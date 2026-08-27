export type AccessItemRefType = 'ENTITLEMENT' | 'ROLE' | 'ACCESS_PROFILE'

export interface AccessItemRef {
    id: string
    type: AccessItemRefType
    name?: string
}

export interface EventSearchDocument {
    attributes?: {
        accessItemId?: string
        accessItemName?: string
        accessItemType?: string
    }
}
