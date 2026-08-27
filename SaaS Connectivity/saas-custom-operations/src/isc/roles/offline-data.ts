import { CatalogAccessItem } from './list-enabled-roles'

export const OFFLINE_ROLES: CatalogAccessItem[] = [
    { id: 'role-offline-1', name: 'Finance Role', type: 'ROLE' },
]

/** Returns offline canned roles for local invoke. */
export function listEnabledRolesOffline(): CatalogAccessItem[] {
    return OFFLINE_ROLES
}
