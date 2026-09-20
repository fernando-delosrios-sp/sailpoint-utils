import { ConnectorError } from '@sailpoint/connector-sdk'
import { AccessRequestsApi } from 'sailpoint-api-client'
import { escapeODataString } from '../../isc/accounts/find-account'
import { normalizeRequestedItem, RequestedAccessItem } from './evaluate'

export interface EvaluateAccessRequestRiskInput {
    accessRequestId?: string
    requestedItems?: Array<{ id?: string; type?: string; name?: string }>
}

interface StatusRow {
    id?: string | null
    accessRequestId?: string | null
    type?: string | null
    name?: string | null
    requestedObject?: { id?: string; type?: string; name?: string } | null
}

function itemFromStatusRow(row: StatusRow, accessRequestId: string): RequestedAccessItem | undefined {
    const requestedObject = row.requestedObject
    if (requestedObject?.id && requestedObject.type) {
        return normalizeRequestedItem(requestedObject)
    }

    const rowId = row.id?.trim()
    if (!rowId || !row.type || rowId === accessRequestId) {
        return undefined
    }
    return normalizeRequestedItem({ id: rowId, type: row.type, name: row.name ?? undefined })
}

/** Uses caller-supplied items when present. Otherwise loads them from access-request status. */
export async function resolveRequestedItems(
    accessRequests: Pick<AccessRequestsApi, 'listAccessRequestStatusV1'>,
    input: EvaluateAccessRequestRiskInput
): Promise<RequestedAccessItem[]> {
    const supplied = (input.requestedItems ?? [])
        .map((item) => normalizeRequestedItem(item))
        .filter((item): item is RequestedAccessItem => Boolean(item))

    if (supplied.length > 0) {
        return supplied
    }

    const accessRequestId = input.accessRequestId?.trim()
    if (!accessRequestId) {
        throw new ConnectorError('Missing required input: requestedItems or accessRequestId')
    }

    const escapedId = escapeODataString(accessRequestId)
    const response = await accessRequests.listAccessRequestStatusV1({
        filters: `accessRequestId eq "${escapedId}"`,
    })
    const rows = (response.data ?? []) as StatusRow[]
    const items = rows
        .map((row) => itemFromStatusRow(row, accessRequestId))
        .filter((item): item is RequestedAccessItem => Boolean(item))

    if (items.length === 0) {
        throw new ConnectorError(
            `Could not resolve requested items for access request ${accessRequestId}. Pass requestedItems from the trigger payload.`
        )
    }
    return items
}
