export type TaggedObjectType =
    | 'ACCESS_PROFILE'
    | 'ENTITLEMENT'
    | 'IDENTITY'
    | 'ROLE'
    | 'SOD_POLICY'
    | 'SOURCE'
    | 'APPLICATION'
    | 'CAMPAIGN'

export interface TaggedObjectRef {
    type: TaggedObjectType
    id: string
}
