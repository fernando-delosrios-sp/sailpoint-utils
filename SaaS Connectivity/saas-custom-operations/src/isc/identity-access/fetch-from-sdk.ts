import { AccessProfilesApi, IdentityHistoryApi, RolesApi } from 'sailpoint-api-client'
import { listAccessProfileEntitlementIds } from '../access-profiles'
import { listAssignedAccessItems } from '../identity-history'
import { listRoleEntitlementIds } from '../roles'
import type { IdentityAccessItem } from './types'

export interface IdentityAccessSdk {
    identityHistory: IdentityHistoryApi
    accessProfiles: AccessProfilesApi
    roles: RolesApi
}

/** Lists access profiles and roles on an identity with entitlement IDs each grants. */
export async function fetchIdentityAccessItemsFromSdk(
    sdk: IdentityAccessSdk,
    identityId: string
): Promise<IdentityAccessItem[]> {
    const [accessProfiles, roles] = await Promise.all([
        listAssignedAccessItems(sdk.identityHistory, identityId, 'accessProfile'),
        listAssignedAccessItems(sdk.identityHistory, identityId, 'role'),
    ])

    const items: IdentityAccessItem[] = []

    for (const profile of accessProfiles) {
        if (!profile.id) {
            continue
        }
        items.push({
            type: 'ACCESS_PROFILE',
            id: profile.id,
            name: profile.displayName ?? profile.id,
            grantedEntitlementIds: await listAccessProfileEntitlementIds(sdk.accessProfiles, profile.id),
        })
    }

    for (const role of roles) {
        if (!role.id) {
            continue
        }
        items.push({
            type: 'ROLE',
            id: role.id,
            name: role.displayName ?? role.id,
            grantedEntitlementIds: await listRoleEntitlementIds(sdk.roles, role.id),
        })
    }

    return items
}
