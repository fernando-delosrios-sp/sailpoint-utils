import { AccessProfilesApi } from 'sailpoint-api-client'

function entitlementIds(items: Array<{ id?: string }>): string[] {
    return items.map((item) => item.id).filter((id): id is string => Boolean(id))
}

/** Returns entitlement IDs granted by an access profile. */
export async function listAccessProfileEntitlementIds(
    accessProfiles: AccessProfilesApi,
    accessProfileId: string
): Promise<string[]> {
    const response = await accessProfiles.getAccessProfileEntitlementsV1({ id: accessProfileId })
    return entitlementIds(response.data ?? [])
}
