import { IdentityHistoryApi } from 'sailpoint-api-client'

export interface AssignedAccessListItem {
    id?: string
    displayName?: string
}

/** Lists access profiles or roles assigned to an identity via IdentityHistoryApi. */
export async function listAssignedAccessItems(
    identityHistory: IdentityHistoryApi,
    identityId: string,
    type: 'accessProfile' | 'role'
): Promise<AssignedAccessListItem[]> {
    const response = await identityHistory.listIdentityAccessItemsV1({
        id: identityId,
        type,
        xSailPointExperimental: 'true',
    })
    return response.data ?? []
}
