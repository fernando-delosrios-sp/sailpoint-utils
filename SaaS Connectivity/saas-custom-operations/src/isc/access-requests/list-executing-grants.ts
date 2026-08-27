import { AccessRequestsApi } from 'sailpoint-api-client'
import { AccessRequestStatusItem } from './types'

/** Lists access request status items in EXECUTING state for an identity. */
export async function listExecutingAccessRequestsForIdentity(
    accessRequests: AccessRequestsApi,
    identityId: string
): Promise<AccessRequestStatusItem[]> {
    const response = await accessRequests.listAccessRequestStatusV1({
        requestedFor: identityId,
        requestState: 'EXECUTING',
    })
    return (response.data ?? []) as AccessRequestStatusItem[]
}

/** Returns EXECUTING access requests whose request type is GRANT_ACCESS. */
export function filterGrantAccessRequests(requests: AccessRequestStatusItem[]): AccessRequestStatusItem[] {
    return requests.filter((request) => request.requestType === 'GRANT_ACCESS')
}

/** Lists EXECUTING GRANT_ACCESS access requests for an identity. */
export async function listExecutingGrantAccessRequestsForIdentity(
    accessRequests: AccessRequestsApi,
    identityId: string
): Promise<AccessRequestStatusItem[]> {
    const executing = await listExecutingAccessRequestsForIdentity(accessRequests, identityId)
    return filterGrantAccessRequests(executing)
}

/** Resolves the events-index tracking number for an access request status item. */
export function resolveAccessRequestTrackingNumber(request: AccessRequestStatusItem): string | undefined {
    return request.accessRequestId ?? request.id ?? undefined
}
