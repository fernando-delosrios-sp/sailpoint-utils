import {
    AccessProfilesApi,
    IdentityHistoryApi,
    RolesApi,
} from 'sailpoint-api-client'
import { EXPERIMENTAL_HEADER } from './isc-client'

export type AccessPathType = 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'

export interface IdentityAccessItem {
    type: AccessPathType
    id: string
    name: string
    /** Entitlement IDs granted through this access profile or role. */
    grantedEntitlementIds?: string[]
}

export interface IdentityAccessSdk {
    identityHistory: IdentityHistoryApi
    accessProfiles: AccessProfilesApi
    roles: RolesApi
}

interface AccessListItem {
    id?: string
    displayName?: string
}

function entitlementIds(items: Array<{ id?: string }>): string[] {
    return items.map((item) => item.id).filter((id): id is string => Boolean(id))
}

async function listAssignedAccessItems(
    identityHistory: IdentityHistoryApi,
    identityId: string,
    type: 'accessProfile' | 'role'
): Promise<AccessListItem[]> {
    const response = await identityHistory.listIdentityAccessItemsV1({
        id: identityId,
        type,
        xSailPointExperimental: 'true',
    })
    return response.data ?? []
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
        const entitlementsResponse = await sdk.accessProfiles.getAccessProfileEntitlementsV1({ id: profile.id })
        items.push({
            type: 'ACCESS_PROFILE',
            id: profile.id,
            name: profile.displayName ?? profile.id,
            grantedEntitlementIds: entitlementIds(entitlementsResponse.data ?? []),
        })
    }

    for (const role of roles) {
        if (!role.id) {
            continue
        }
        const entitlementsResponse = await sdk.roles.getRoleEntitlementsV1({ id: role.id })
        items.push({
            type: 'ROLE',
            id: role.id,
            name: role.displayName ?? role.id,
            grantedEntitlementIds: entitlementIds(entitlementsResponse.data ?? []),
        })
    }

    return items
}

/** Offline/test fallback when ISC credentials are unavailable. */
export async function fetchIdentityAccessItemsOffline(identityId: string): Promise<IdentityAccessItem[]> {
    return OFFLINE_IDENTITY_ACCESS_FIXTURES[identityId] ?? []
}

/** Deterministic access items for offline SOD remediation and local operation tests. */
const OFFLINE_IDENTITY_ACCESS_FIXTURES: Record<string, IdentityAccessItem[]> = {
    'offline-identity': [
        {
            type: 'ACCESS_PROFILE',
            id: 'offline-ap-a',
            name: 'Offline Finance AP',
            grantedEntitlementIds: ['offline-ent-a'],
        },
    ],
}

export { EXPERIMENTAL_HEADER }



