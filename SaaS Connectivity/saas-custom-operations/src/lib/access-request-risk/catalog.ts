import { ConnectorError } from '@sailpoint/connector-sdk'
import { AccessProfilesApi, EntitlementsApi, RolesApi } from 'sailpoint-api-client'
import { listAccessProfileEntitlementIds } from '../../isc/access-profiles/access-profile-entitlements'
import { listRoleEntitlementIds } from '../../isc/roles/role-entitlements'
import { memoizeAsync } from '../../framework/concurrency'
import { SailPointClients } from '../../framework/types'
import { AccessProfileSnapshot, AccessRiskCatalog, EntitlementSnapshot, RoleSnapshot } from './evaluate'

function metadataOf(data: { accessModelMetadata?: unknown } | undefined): unknown {
    return data?.accessModelMetadata
}

function effectivePrivilege(data: { privilegeLevel?: { effective?: string | null } | null } | undefined): string | null {
    return data?.privilegeLevel?.effective ?? null
}

export interface AccessRiskCatalogOptions {
    /**
     * Optional request-scoped caches for role/access-profile entitlement expansion.
     * When provided (combined pre-check), SoD expansion can reuse the same lookups.
     */
    listRoleEntitlementIds?: (roleId: string) => Promise<string[]>
    listAccessProfileEntitlementIds?: (accessProfileId: string) => Promise<string[]>
}

export function createLiveAccessRiskCatalog(
    clients: {
        roles: RolesApi
        accessProfiles: AccessProfilesApi
        entitlements: EntitlementsApi
    },
    options: AccessRiskCatalogOptions = {}
): AccessRiskCatalog {
    const listRoleIds = options.listRoleEntitlementIds ?? ((id: string) => listRoleEntitlementIds(clients.roles, id))
    const listProfileIds =
        options.listAccessProfileEntitlementIds ??
        ((id: string) => listAccessProfileEntitlementIds(clients.accessProfiles, id))

    const getRole = memoizeAsync(async (id: string): Promise<RoleSnapshot> => {
        const response = await clients.roles.getRoleV1({ id })
        if (!response.data) {
            throw new ConnectorError(`Role not found: ${id}`)
        }
        const accessProfileIds = (response.data.accessProfiles ?? [])
            .map((profile) => profile.id)
            .filter((profileId): profileId is string => Boolean(profileId))
        const entitlementIds = await listRoleIds(id)
        return {
            metadata: metadataOf(response.data),
            accessProfileIds,
            entitlementIds,
        }
    })

    const getAccessProfile = memoizeAsync(async (id: string): Promise<AccessProfileSnapshot> => {
        const response = await clients.accessProfiles.getAccessProfileV1({ id })
        if (!response.data) {
            throw new ConnectorError(`Access profile not found: ${id}`)
        }
        const entitlementIds = await listProfileIds(id)
        return {
            metadata: metadataOf(response.data),
            entitlementIds,
        }
    })

    const getEntitlement = memoizeAsync(async (id: string): Promise<EntitlementSnapshot> => {
        const response = await clients.entitlements.getEntitlementV1({ id })
        if (!response.data) {
            throw new ConnectorError(`Entitlement not found: ${id}`)
        }
        return {
            effectivePrivilege: effectivePrivilege(response.data),
            metadata: metadataOf(response.data),
        }
    })

    return { getRole, getAccessProfile, getEntitlement }
}

const OFFLINE_ENTITLEMENTS: Record<string, EntitlementSnapshot> = {
    'offline-ent-high': { effectivePrivilege: 'HIGH', metadata: undefined },
    'offline-ent-medium': { effectivePrivilege: 'LOW', metadata: risk('medium') },
    'offline-ent-low': { effectivePrivilege: 'LOW', metadata: undefined },
}

function risk(value: string): unknown {
    return {
        attributes: [{ key: 'iscRisk', name: 'Risk', values: [{ value, name: value }] }],
    }
}

/** Canned catalog for config-less local invoke. Unknown ids fail closed. */
export function createOfflineAccessRiskCatalog(): AccessRiskCatalog {
    return {
        async getRole(id: string): Promise<RoleSnapshot> {
            if (id === 'offline-role-wrapped') {
                return {
                    metadata: risk('low'),
                    accessProfileIds: ['offline-ap-low'],
                    entitlementIds: ['offline-ent-high'],
                }
            }
            throw new ConnectorError(`Offline role not found: ${id}`)
        },
        async getAccessProfile(id: string): Promise<AccessProfileSnapshot> {
            if (id === 'offline-ap-low') {
                return { metadata: undefined, entitlementIds: ['offline-ent-low'] }
            }
            throw new ConnectorError(`Offline access profile not found: ${id}`)
        },
        async getEntitlement(id: string): Promise<EntitlementSnapshot> {
            const entitlement = OFFLINE_ENTITLEMENTS[id]
            if (!entitlement) {
                throw new ConnectorError(`Offline entitlement not found: ${id}`)
            }
            return entitlement
        },
    }
}

export function createAccessRiskCatalog(
    offline: boolean,
    clients: SailPointClients,
    options: AccessRiskCatalogOptions = {}
): AccessRiskCatalog {
    if (offline) {
        return createOfflineAccessRiskCatalog()
    }
    return createLiveAccessRiskCatalog(clients, options)
}
