import { ConnectorError } from '@sailpoint/connector-sdk'
import { CatalogAccessItem } from './list-enabled-roles'

/** Canned access item owner identity ids for offline invokes. */
export const OFFLINE_ACCESS_ITEM_OWNERS: Record<string, string> = {
    'role-offline-1': 'item-owner-offline-1',
    'ap-offline-1': 'item-owner-offline-1',
}

/** Returns a deterministic offline access item owner id for known catalog items. */
export function resolveCatalogAccessItemOwnerIdOffline(item: CatalogAccessItem): string {
    const ownerId = OFFLINE_ACCESS_ITEM_OWNERS[item.id]
    if (!ownerId) {
        throw new ConnectorError(`${item.type} ${item.id} has no offline owner mapping`)
    }
    return ownerId
}
