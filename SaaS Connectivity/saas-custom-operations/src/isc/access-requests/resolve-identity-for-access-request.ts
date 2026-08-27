import { ConnectorError } from '@sailpoint/connector-sdk'
import { AccessRequestsApi } from 'sailpoint-api-client'
import { escapeODataString } from '../accounts'
import { filterGrantAccessRequests } from './list-executing-grants'
import { matchesAccessRequestId } from './matches-access-request-id'
import { resolveIdentityIdForAccessRequestOffline } from './offline-data'
import type { AccessRequestStatusItem } from './types'

/** Resolves the target identity id for an EXECUTING GRANT_ACCESS access request. */
export async function resolveIdentityIdForAccessRequest(
    accessRequests: AccessRequestsApi,
    accessRequestId: string
): Promise<string> {
    const escapedId = escapeODataString(accessRequestId)
    const response = await accessRequests.listAccessRequestStatusV1({
        requestState: 'EXECUTING',
        filters: `accessRequestId eq "${escapedId}"`,
    })
    const items = (response.data ?? []) as AccessRequestStatusItem[]
    const grant = filterGrantAccessRequests(items).find((item) => matchesAccessRequestId(item, accessRequestId))
    const identityId = grant?.requestedFor?.id?.trim()

    if (!identityId) {
        throw new ConnectorError(
            `Could not resolve identity for EXECUTING GRANT_ACCESS access request: ${accessRequestId}`
        )
    }

    return identityId
}

export { resolveIdentityIdForAccessRequestOffline }
