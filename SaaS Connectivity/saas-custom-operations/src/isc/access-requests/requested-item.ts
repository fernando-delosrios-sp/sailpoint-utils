import {
    AccessProfilesApi,
    EntitlementsApi,
    RolesApi,
} from 'sailpoint-api-client'
import type { RequestedItemType } from './entitlement-types'

/** Returns access model metadata for a requested access item. */
export async function getRequestedItemMetadata(
    clients: { roles: RolesApi; accessProfiles: AccessProfilesApi; entitlements: EntitlementsApi },
    id: string,
    type: RequestedItemType
): Promise<Record<string, unknown> | null> {
    try {
        if (type === 'ROLE') {
            const response = await clients.roles.getRoleV1({ id })
            return (response.data?.accessModelMetadata as Record<string, unknown> | undefined) ?? null
        }
        if (type === 'ACCESS_PROFILE') {
            const response = await clients.accessProfiles.getAccessProfileV1({ id })
            return (response.data?.accessModelMetadata as Record<string, unknown> | undefined) ?? null
        }
        const response = await clients.entitlements.getEntitlementV1({ id })
        return (response.data?.accessModelMetadata as Record<string, unknown> | undefined) ?? null
    } catch (error) {
        console.error(`[getRequestedItemMetadata] Error fetching metadata for ${type} ${id}:`, error)
        return null
    }
}

/** Returns the owner identity id for a requested access item. */
export async function getRequestedItemOwnerId(
    clients: { roles: RolesApi; accessProfiles: AccessProfilesApi; entitlements: EntitlementsApi },
    id: string,
    type: RequestedItemType
): Promise<string> {
    try {
        if (type === 'ROLE') {
            const response = await clients.roles.getRoleV1({ id })
            return response.data?.owner?.id ?? 'N/A'
        }
        if (type === 'ACCESS_PROFILE') {
            const response = await clients.accessProfiles.getAccessProfileV1({ id })
            return response.data?.owner?.id ?? 'N/A'
        }
        const response = await clients.entitlements.getEntitlementV1({ id })
        return response.data?.owner?.id ?? 'N/A'
    } catch (error) {
        console.error(`[getRequestedItemOwnerId] Error fetching owner for ${type} ${id}:`, error)
        return 'N/A'
    }
}
