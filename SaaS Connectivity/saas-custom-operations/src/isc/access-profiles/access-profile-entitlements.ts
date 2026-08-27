import { AccessProfilesApi } from 'sailpoint-api-client'

export interface EntitlementRef {
    id: string
    name?: string
}

function toEntitlementRefs(items: Array<{ id?: string; name?: string }>): EntitlementRef[] {
    return items
        .filter((item): item is { id: string; name?: string } => Boolean(item.id))
        .map((item) => ({ id: item.id, name: item.name }))
}

/** Returns entitlements granted by an access profile. */
export async function listAccessProfileEntitlements(
    accessProfiles: AccessProfilesApi,
    accessProfileId: string
): Promise<EntitlementRef[]> {
    const response = await accessProfiles.getAccessProfileEntitlementsV1({ id: accessProfileId })
    return toEntitlementRefs(response.data ?? [])
}

/** Returns entitlement IDs granted by an access profile. */
export async function listAccessProfileEntitlementIds(
    accessProfiles: AccessProfilesApi,
    accessProfileId: string
): Promise<string[]> {
    const entitlements = await listAccessProfileEntitlements(accessProfiles, accessProfileId)
    return entitlements.map((entitlement) => entitlement.id)
}
