import { AccessProfilesApi, JsonPatchOperation } from 'sailpoint-api-client'
import { listAccessProfileEntitlements } from './access-profile-entitlements'

function buildReplacePatch(path: string, value: unknown): JsonPatchOperation {
    return { op: 'replace', path, value: value as JsonPatchOperation['value'] }
}

async function patchAccessProfile(
    accessProfiles: AccessProfilesApi,
    accessProfileId: string,
    operations: JsonPatchOperation[]
): Promise<void> {
    if (operations.length === 0) {
        return
    }
    await accessProfiles.patchAccessProfileV1({ id: accessProfileId, jsonPatchOperation: operations })
}

/** Removes entitlements from an access profile while preserving other fields. */
export async function removeAccessProfileEntitlements(
    accessProfiles: AccessProfilesApi,
    accessProfileId: string,
    entitlementIds: string[]
): Promise<void> {
    if (entitlementIds.length === 0) {
        return
    }

    const removeSet = new Set(entitlementIds)
    const current = await listAccessProfileEntitlements(accessProfiles, accessProfileId)
    const filtered = current
        .filter((entitlement) => !removeSet.has(entitlement.id))
        .map((entitlement) => ({ id: entitlement.id, name: entitlement.name }))
    await patchAccessProfile(accessProfiles, accessProfileId, [buildReplacePatch('/entitlements', filtered)])
}

/** Appends an audit line to an access profile description. */
export async function appendAccessProfileDescription(
    accessProfiles: AccessProfilesApi,
    accessProfileId: string,
    auditLine: string
): Promise<void> {
    const response = await accessProfiles.getAccessProfileV1({ id: accessProfileId })
    const existing = response.data?.description ?? ''
    const separator = existing.length > 0 ? '\n' : ''
    await patchAccessProfile(accessProfiles, accessProfileId, [
        buildReplacePatch('/description', `${existing}${separator}${auditLine}`),
    ])
}

export interface AccessProfileCompositionPatch {
    removeEntitlementIds?: string[]
    descriptionAppend?: string
}

/** Applies access profile entitlement and description changes in a single PATCH request. */
export async function patchAccessProfileComposition(
    accessProfiles: AccessProfilesApi,
    accessProfileId: string,
    changes: AccessProfileCompositionPatch
): Promise<void> {
    const operations: JsonPatchOperation[] = []
    let profileData = null

    if (changes.descriptionAppend) {
        profileData = (await accessProfiles.getAccessProfileV1({ id: accessProfileId })).data
    }

    if (changes.removeEntitlementIds?.length) {
        const removeSet = new Set(changes.removeEntitlementIds)
        const current = await listAccessProfileEntitlements(accessProfiles, accessProfileId)
        const filtered = current
            .filter((entitlement) => !removeSet.has(entitlement.id))
            .map((entitlement) => ({ id: entitlement.id, name: entitlement.name }))
        operations.push(buildReplacePatch('/entitlements', filtered))
    }

    if (changes.descriptionAppend) {
        const existing = profileData?.description ?? ''
        const separator = existing.length > 0 ? '\n' : ''
        operations.push(
            buildReplacePatch('/description', `${existing}${separator}${changes.descriptionAppend}`)
        )
    }

    await patchAccessProfile(accessProfiles, accessProfileId, operations)
}
