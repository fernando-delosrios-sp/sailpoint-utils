import { AccessRequestsApi } from 'sailpoint-api-client'
import type { GetAccessRequestStatus } from './entitlement-types'

/** Fetches a single access request status record by accessRequestId. */
export async function fetchAccessRequestById(
    accessRequests: AccessRequestsApi,
    accessRequestId: string
): Promise<GetAccessRequestStatus | null> {
    try {
        const response = await accessRequests.listAccessRequestStatusV1({
            filters: `accessRequestId eq "${accessRequestId}"`,
        })
        const items = response.data ?? []
        return (items[0] as GetAccessRequestStatus | undefined) ?? null
    } catch (error) {
        console.error(`[fetchAccessRequestById] Error fetching access request ${accessRequestId}:`, error)
        return null
    }
}
