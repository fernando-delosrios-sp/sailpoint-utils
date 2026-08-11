import { RolesApi } from 'sailpoint-api-client'

function entitlementIds(items: Array<{ id?: string }>): string[] {
    return items.map((item) => item.id).filter((id): id is string => Boolean(id))
}

/** Returns entitlement IDs granted by a role. */
export async function listRoleEntitlementIds(roles: RolesApi, roleId: string): Promise<string[]> {
    const response = await roles.getRoleEntitlementsV1({ id: roleId })
    return entitlementIds(response.data ?? [])
}
