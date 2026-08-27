import { ExpandedAccessItemEntitlements } from './expand-access-item-entitlements'
import { CatalogAccessItem } from '../../isc/roles/list-enabled-roles'

/** Offline entitlement expansion keyed by catalog item id. */
export const OFFLINE_EXPANDED_ENTITLEMENTS: Record<
    string,
    { entitlementIds: string[]; nestedProfiles?: ExpandedAccessItemEntitlements['nestedProfiles'] }
> = {
    'role-offline-1': {
        entitlementIds: ['ent-a', 'ent-c'],
        nestedProfiles: [
            {
                id: 'ap-offline-1',
                name: 'SAP Suite',
                entitlements: [{ id: 'ent-c', name: 'Accounts Payable' }],
            },
        ],
    },
    'ap-offline-1': {
        entitlementIds: ['ent-c'],
    },
}

/** Expands entitlements for offline catalog items without live API calls. */
export function expandAccessItemEntitlementsOffline(item: CatalogAccessItem): ExpandedAccessItemEntitlements {
    const mapping = OFFLINE_EXPANDED_ENTITLEMENTS[item.id] ?? { entitlementIds: [] }
    const entitlementIds = new Set(mapping.entitlementIds)
    const entitlementNames: Record<string, string> = {
        'ent-a': 'Accounts Receivable',
        'ent-c': 'Accounts Payable',
    }
    const entitlements = mapping.entitlementIds.map((id) => ({ id, name: entitlementNames[id] }))
    const nestedProfiles = mapping.nestedProfiles ?? []

    return { entitlementIds, entitlements, nestedProfiles }
}
