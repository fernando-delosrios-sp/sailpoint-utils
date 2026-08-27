import { AccessRequestStatusItem } from './types'
import { matchesAccessRequestId } from './matches-access-request-id'

export const OFFLINE_EXECUTING_GRANT_REQUEST: AccessRequestStatusItem = {
    id: 'offline-item-001',
    accessRequestId: 'offline-tracking-001',
    name: 'Offline Analyst Role',
    type: 'ROLE',
    requestType: 'GRANT_ACCESS',
    state: 'EXECUTING',
    requestedFor: { id: 'offline-preventive-identity' },
}

/** Returns canned EXECUTING GRANT_ACCESS requests for offline operation tests. */
export function listExecutingGrantAccessRequestsForIdentityOffline(identityId: string): AccessRequestStatusItem[] {
    if (identityId === 'offline-preventive-empty') {
        return []
    }
    return [OFFLINE_EXECUTING_GRANT_REQUEST]
}

/** Resolves target identity id from an offline access request id or tracking number. */
export function resolveIdentityIdForAccessRequestOffline(accessRequestId: string): string | undefined {
    if (matchesAccessRequestId(OFFLINE_EXECUTING_GRANT_REQUEST, accessRequestId)) {
        return OFFLINE_EXECUTING_GRANT_REQUEST.requestedFor?.id ?? undefined
    }
    return undefined
}
