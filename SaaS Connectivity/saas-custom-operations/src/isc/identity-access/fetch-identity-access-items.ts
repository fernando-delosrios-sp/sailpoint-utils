import { listAssignedAccessItems } from '../identity-history'
import { listRoleEntitlementIds } from '../roles'
import type { IdentityAccessItem, IdentityAccessSdk } from './types'

/** Lists roles on an identity with entitlement IDs each grants. */
export async function fetchIdentityAccessItemsFromSdk(
    sdk: IdentityAccessSdk,
    identityId: string
): Promise<IdentityAccessItem[]> {
    const roles = await listAssignedAccessItems(sdk.identityHistory, identityId, 'role')

    const items: IdentityAccessItem[] = []

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
