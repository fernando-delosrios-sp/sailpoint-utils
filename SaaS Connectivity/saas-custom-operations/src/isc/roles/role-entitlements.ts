import { RolesApi } from 'sailpoint-api-client'

export interface EntitlementRef {
    id: string
    name?: string
}

function toEntitlementRefs(items: Array<{ id?: string; name?: string }>): EntitlementRef[] {
    return items
        .filter((item): item is { id: string; name?: string } => Boolean(item.id))
        .map((item) => ({ id: item.id, name: item.name }))
}

/** Returns entitlements granted by a role. */
export async function listRoleEntitlements(roles: RolesApi, roleId: string): Promise<EntitlementRef[]> {
    const response = await roles.getRoleEntitlementsV1({ id: roleId })
    return toEntitlementRefs(response.data ?? [])
}

/** Returns entitlement IDs granted by a role. */
export async function listRoleEntitlementIds(roles: RolesApi, roleId: string): Promise<string[]> {
    const entitlements = await listRoleEntitlements(roles, roleId)
    return entitlements.map((entitlement) => entitlement.id)
}
