import { IdentitiesApi } from 'sailpoint-api-client'

/** Fetches display context for an identity used in approval emails. */
export async function fetchIdentityDisplayContext(
    identities: IdentitiesApi,
    identityId: string
): Promise<{ displayName: string; managerRefName: string }> {
    try {
        const response = await identities.getIdentityV1({ id: identityId })
        const identity = response.data
        const attributes = identity?.attributes as Record<string, string> | undefined
        return {
            displayName: attributes?.displayName ?? identity?.name ?? 'User',
            managerRefName: identity?.managerRef?.name ?? 'Approver',
        }
    } catch (error) {
        console.error(`[fetchIdentityDisplayContext] Error fetching identity ${identityId}:`, error)
        return {
            displayName: 'User',
            managerRefName: 'Approver',
        }
    }
}
