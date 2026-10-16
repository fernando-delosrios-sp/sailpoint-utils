import { ConnectorError } from '@sailpoint/connector-sdk'
import { AccessRequestsApi } from 'sailpoint-api-client'
import { escapeODataString } from '../../isc/accounts/find-account'
import { normalizeRequestedItem, RequestedAccessItem } from './evaluate'

export type RequestedItemLike = { id?: string; type?: string; name?: string }

export interface EvaluateAccessRequestRiskInput {
    accessRequestId?: string
    /** ISC collapses a single-element `$.trigger.requestedItems` to a bare object on invoke. */
    requestedItems?: RequestedItemLike[] | RequestedItemLike | string
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

/** Accepts the array, the single object ISC sends for a one-item request, or a JSON string of either. */
export function toRequestedItemArray(
    requestedItems: EvaluateAccessRequestRiskInput['requestedItems']
): RequestedItemLike[] {
    if (requestedItems == null) {
        return []
    }

    if (typeof requestedItems === 'string') {
        const trimmed = requestedItems.trim()
        if (!trimmed) {
            return []
        }
        try {
            return toRequestedItemArray(JSON.parse(trimmed))
        } catch {
            throw new ConnectorError(`Input requestedItems is a string that is not valid JSON: ${trimmed}`)
        }
    }

    if (Array.isArray(requestedItems)) {
        return requestedItems.filter((item): item is RequestedItemLike => typeof item === 'object' && item !== null)
    }

    if (typeof requestedItems === 'object') {
        return [requestedItems]
    }

    throw new ConnectorError(`Input requestedItems must be an object or an array, got ${typeof requestedItems}`)
}

/** Uses caller-supplied items when present. Otherwise loads them from access-request status. */
export async function resolveRequestedItems(
    accessRequests: Pick<AccessRequestsApi, 'listAccessRequestStatusV1'>,
    input: EvaluateAccessRequestRiskInput
): Promise<RequestedAccessItem[]> {
    const supplied = toRequestedItemArray(input.requestedItems)
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
