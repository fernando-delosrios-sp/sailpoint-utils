/** ACCESS_PROFILE assignment with a scheduled removeDate. */
export interface SunsetAccessProfileAssignment {
    id: string
    name: string
    removeDate: string
    sourceName?: string
}

/** Identity hit that carries one or more sunset ACCESS_PROFILE assignments. */
export interface IdentityWithSunsetAccessProfiles {
    id: string
    displayName: string
    managerId?: string
    accessProfiles: SunsetAccessProfileAssignment[]
}
