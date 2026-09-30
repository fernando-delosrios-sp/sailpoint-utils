import { ConnectorError } from '@sailpoint/connector-sdk'
import {
    resolveIdentityIdForAccessRequest,
    resolveIdentityIdForAccessRequestOffline,
} from '../../isc/access-requests'
import type { AccessItemRef, AccessItemRefType } from '../../isc/events-search'
import { SailPointClients } from '../../framework/types'

export interface ResolvedPreventiveSodCheckInput {
    identityId: string
    accessRequestId?: string
    inflightOnly: boolean
    requestedItems: AccessItemRef[]
    waitForPersist: boolean
}

/** Workflow and invoke payloads send booleans as strings. Omitted inflightOnly is false. */
export function parseInflightOnly(value: unknown): boolean {
    if (value === true || value === 1) {
        return true
    }
    if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase()
        return normalized === 'true' || normalized === '1' || normalized === 'yes'
    }
    return false
}

/** Workflow and invoke payloads send booleans as strings. Omitted waitForPersist is true. */
export function parseWaitForPersist(value: unknown): boolean {
    if (value === false || value === 0) {
        return false
    }
    if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase()
        return !['false', '0', 'no'].includes(normalized)
    }
    return true
}

type RequestedItemLike = { id?: string; type?: string; name?: string }

function normalizeRequestedItem(item: RequestedItemLike): AccessItemRef | undefined {
    const id = item.id?.trim()
    const type = item.type?.trim().toUpperCase().replace(/[\s-]+/g, '_') as AccessItemRefType | undefined
    if (!id || !type || !['ENTITLEMENT', 'ROLE', 'ACCESS_PROFILE'].includes(type)) {
        return undefined
    }
    const name = item.name?.trim() || undefined
    return { id, type, ...(name ? { name } : {}) }
}

/** Accepts the array, single object, or JSON string shape emitted by ISC workflows. */
export function parseRequestedItems(value: unknown): AccessItemRef[] {
    if (value == null || value === '') {
        return []
    }
    if (typeof value === 'string') {
        try {
            return parseRequestedItems(JSON.parse(value))
        } catch {
            throw new ConnectorError('Input requestedItems is not valid JSON')
        }
    }
    const items = Array.isArray(value) ? value : [value]
    return items
        .filter((item): item is RequestedItemLike => typeof item === 'object' && item !== null)
        .map(normalizeRequestedItem)
        .filter((item): item is AccessItemRef => Boolean(item))
}

/** Resolves effective identity and request mode from preventive-sod-check invoke input. */
export async function resolvePreventiveSodCheckInput(
    _requestId: string,
    sdk: SailPointClients,
    input: {
        identityId?: string
        accessRequestId?: string
        inflightOnly?: boolean | string
        requestedItems?: unknown
        waitForPersist?: boolean | string
    },
    offline: boolean
): Promise<ResolvedPreventiveSodCheckInput> {
    const accessRequestId = input.accessRequestId?.trim() || undefined
    const providedIdentityId = input.identityId?.trim() || undefined
    const inflightOnly = parseInflightOnly(input.inflightOnly)
    const requestedItems = parseRequestedItems(input.requestedItems)
    const waitForPersist = parseWaitForPersist(input.waitForPersist)

    if (!accessRequestId && !providedIdentityId) {
        throw new ConnectorError('Missing required input: identityId or accessRequestId')
    }

    if (accessRequestId && !providedIdentityId) {
        const identityId = offline
            ? resolveIdentityIdForAccessRequestOffline(accessRequestId)
            : await resolveIdentityIdForAccessRequest(sdk.accessRequests, accessRequestId)

        if (!identityId) {
            throw new ConnectorError(`Could not resolve identity for access request: ${accessRequestId}`)
        }

        return { identityId, accessRequestId, inflightOnly, requestedItems, waitForPersist }
    }

    return {
        identityId: providedIdentityId!,
        accessRequestId,
        inflightOnly,
        requestedItems,
        waitForPersist,
    }
}
