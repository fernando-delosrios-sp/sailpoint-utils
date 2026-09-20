import { ConnectorError } from '@sailpoint/connector-sdk'
import { AccessProfilesApi, EntitlementsApi, RolesApi } from 'sailpoint-api-client'
import { listAccessProfileEntitlementIds } from '../../isc/access-profiles/access-profile-entitlements'
import { listRoleEntitlementIds } from '../../isc/roles/role-entitlements'
import { SailPointClients } from '../../framework/types'
import { AccessProfileSnapshot, AccessRiskCatalog, EntitlementSnapshot, RoleSnapshot } from './evaluate'

function metadataOf(data: { accessModelMetadata?: unknown } | undefined): unknown {
    return data?.accessModelMetadata
}

function effectivePrivilege(data: { privilegeLevel?: { effective?: string | null } | null } | undefined): string | null {
    return data?.privilegeLevel?.effective ?? null
}

export function createLiveAccessRiskCatalog(clients: {
    roles: RolesApi
    accessProfiles: AccessProfilesApi
    entitlements: EntitlementsApi
}): AccessRiskCatalog {
    return {
        async getRole(id: string): Promise<RoleSnapshot> {
            const response = await clients.roles.getRoleV1({ id })
            if (!response.data) {
                throw new ConnectorError(`Role not found: ${id}`)
            }
            const accessProfileIds = (response.data.accessProfiles ?? [])
                .map((profile) => profile.id)
                .filter((profileId): profileId is string => Boolean(profileId))
            const entitlementIds = await listRoleEntitlementIds(clients.roles, id)
            return {
                metadata: metadataOf(response.data),
                accessProfileIds,
                entitlementIds,
            }
        },
        async getAccessProfile(id: string): Promise<AccessProfileSnapshot> {
            const response = await clients.accessProfiles.getAccessProfileV1({ id })
            if (!response.data) {
                throw new ConnectorError(`Access profile not found: ${id}`)
            }
            const entitlementIds = await listAccessProfileEntitlementIds(clients.accessProfiles, id)
            return {
                metadata: metadataOf(response.data),
                entitlementIds,
            }
        },
        async getEntitlement(id: string): Promise<EntitlementSnapshot> {
            const response = await clients.entitlements.getEntitlementV1({ id })
            if (!response.data) {
                throw new ConnectorError(`Entitlement not found: ${id}`)
            }
            return {
                effectivePrivilege: effectivePrivilege(response.data),
                metadata: metadataOf(response.data),
            }
        },
    }
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

export function createAccessRiskCatalog(offline: boolean, clients: SailPointClients): AccessRiskCatalog {
    if (offline) {
        return createOfflineAccessRiskCatalog()
    }
    return createLiveAccessRiskCatalog(clients)
}
