import { IdentityHistoryApi } from 'sailpoint-api-client'

export interface AssignedEntitlementItem {
    id: string
    displayName: string
    privileged: boolean
}

/** Lists entitlements assigned to an identity via IdentityHistoryApi. */
export async function listAssignedEntitlements(
    identityHistory: IdentityHistoryApi,
    identityId: string
): Promise<AssignedEntitlementItem[]> {
    const response = await identityHistory.listIdentityAccessItemsV1({
        id: identityId,
        type: 'entitlement',
        xSailPointExperimental: 'true',
    })

    return (response.data ?? [])
        .filter((item): item is typeof item & { id: string } => Boolean(item.id))
        .map((item) => ({
            id: item.id,
            displayName: item.displayName ?? item.id,
            privileged: item.privileged === true,
        }))
}
