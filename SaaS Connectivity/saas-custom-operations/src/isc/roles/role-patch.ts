import { JsonPatchOperation, RolesApi } from 'sailpoint-api-client'
import { listRoleEntitlements } from './role-entitlements'

function buildReplacePatch(path: string, value: unknown): JsonPatchOperation {
    return { op: 'replace', path, value: value as JsonPatchOperation['value'] }
}

async function patchRole(roles: RolesApi, roleId: string, operations: JsonPatchOperation[]): Promise<void> {
    if (operations.length === 0) {
        return
    }
    await roles.patchRoleV1({ id: roleId, jsonPatchOperation: operations })
}

/** Detaches access profiles from a role while preserving other role fields. */
export async function detachRoleAccessProfiles(
    roles: RolesApi,
    roleId: string,
    accessProfileIds: string[]
): Promise<void> {
    if (accessProfileIds.length === 0) {
        return
    }

    const detachSet = new Set(accessProfileIds)
    const response = await roles.getRoleV1({ id: roleId })
    const current = response.data?.accessProfiles ?? []
    const filtered = current.filter((profile) => profile.id && !detachSet.has(profile.id))
    await patchRole(roles, roleId, [buildReplacePatch('/accessProfiles', filtered)])
}

/** Removes direct entitlements from a role while preserving other role fields. */
export async function removeRoleEntitlements(
    roles: RolesApi,
    roleId: string,
    entitlementIds: string[]
): Promise<void> {
    if (entitlementIds.length === 0) {
        return
    }

    const removeSet = new Set(entitlementIds)
    const current = await listRoleEntitlements(roles, roleId)
    const filtered = current
        .filter((entitlement) => !removeSet.has(entitlement.id))
        .map((entitlement) => ({ id: entitlement.id, name: entitlement.name }))
    await patchRole(roles, roleId, [buildReplacePatch('/entitlements', filtered)])
}

/** Appends an audit line to a role description. */
export async function appendRoleDescription(roles: RolesApi, roleId: string, auditLine: string): Promise<void> {
    const response = await roles.getRoleV1({ id: roleId })
    const existing = response.data?.description ?? ''
    const separator = existing.length > 0 ? '\n' : ''
    await patchRole(roles, roleId, [buildReplacePatch('/description', `${existing}${separator}${auditLine}`)])
}

export interface RoleCompositionPatch {
    detachAccessProfileIds?: string[]
    removeEntitlementIds?: string[]
    descriptionAppend?: string
}

/** Applies role composition and description changes in a single PATCH request. */
export async function patchRoleComposition(
    roles: RolesApi,
    roleId: string,
    changes: RoleCompositionPatch
): Promise<void> {
    const operations: JsonPatchOperation[] = []
    let roleData = null

    const needsRoleGet =
        (changes.detachAccessProfileIds?.length ?? 0) > 0 || Boolean(changes.descriptionAppend)

    if (needsRoleGet) {
        roleData = (await roles.getRoleV1({ id: roleId })).data
    }

    if (changes.detachAccessProfileIds?.length) {
        const detachSet = new Set(changes.detachAccessProfileIds)
        const filtered = (roleData?.accessProfiles ?? []).filter(
            (profile) => profile.id && !detachSet.has(profile.id)
        )
        operations.push(buildReplacePatch('/accessProfiles', filtered))
    }

    if (changes.removeEntitlementIds?.length) {
        const removeSet = new Set(changes.removeEntitlementIds)
        const current = await listRoleEntitlements(roles, roleId)
        const filtered = current
            .filter((entitlement) => !removeSet.has(entitlement.id))
            .map((entitlement) => ({ id: entitlement.id, name: entitlement.name }))
        operations.push(buildReplacePatch('/entitlements', filtered))
    }

    if (changes.descriptionAppend) {
        const existing = roleData?.description ?? ''
        const separator = existing.length > 0 ? '\n' : ''
        operations.push(
            buildReplacePatch('/description', `${existing}${separator}${changes.descriptionAppend}`)
        )
    }

    await patchRole(roles, roleId, operations)
}
