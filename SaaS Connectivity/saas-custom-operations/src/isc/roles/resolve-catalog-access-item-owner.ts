import { AccessProfilesApi, RolesApi } from 'sailpoint-api-client'
import { ConnectorError } from '@sailpoint/connector-sdk'
import { CatalogAccessItem } from './list-enabled-roles'
import { resolveRoleOwnerId } from './resolve-role-owner'
import { resolveAccessProfileOwnerId } from '../access-profiles/resolve-access-profile-owner'
import { toConnectorError } from '../../framework/connector-error'

export interface CatalogAccessItemOwnerClients {
    roles: RolesApi
    accessProfiles: AccessProfilesApi
}

/** Fetches a catalog access item and returns its primary IDENTITY owner id. */
export async function resolveCatalogAccessItemOwnerId(
    clients: CatalogAccessItemOwnerClients,
    item: CatalogAccessItem
): Promise<string> {
    if (item.type === 'ROLE') {
        try {
            const response = await clients.roles.getRoleV1({ id: item.id })
            return resolveRoleOwnerId(item.id, response.data?.owner ?? undefined)
        } catch (error) {
            if (error instanceof ConnectorError) {
                throw error
            }
            throw toConnectorError(error, `Failed to resolve owner for role ${item.id}`)
        }
    }

    try {
        const response = await clients.accessProfiles.getAccessProfileV1({ id: item.id })
        return resolveAccessProfileOwnerId(item.id, response.data?.owner ?? undefined)
    } catch (error) {
        if (error instanceof ConnectorError) {
            throw error
        }
        throw toConnectorError(error, `Failed to resolve owner for access profile ${item.id}`)
    }
}
