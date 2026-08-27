import { CatalogAccessItem } from '../roles/list-enabled-roles'

export const OFFLINE_ACCESS_PROFILES: CatalogAccessItem[] = [
    { id: 'ap-offline-1', name: 'SAP Suite', type: 'ACCESS_PROFILE' },
]

/** Returns offline canned access profiles for local invoke. */
export function listEnabledAccessProfilesOffline(): CatalogAccessItem[] {
    return OFFLINE_ACCESS_PROFILES
}
