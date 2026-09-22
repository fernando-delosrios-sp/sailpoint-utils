import { ConnectorError } from '@sailpoint/connector-sdk'
import { getActiveFrameworkLogger } from '../../framework/logger'
import {
    resolveIdentityIdForAccessRequest,
    resolveIdentityIdForAccessRequestOffline,
} from '../../isc/access-requests'
import { SailPointClients } from '../../framework/types'

export interface ResolvedPreventiveSodCheckInput {
    identityId: string
    accessRequestId?: string
    inflightOnly: boolean
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

/** Resolves effective identity and request mode from preventive-sod-check invoke input. */
export async function resolvePreventiveSodCheckInput(
    requestId: string,
    sdk: SailPointClients,
    input: { identityId?: string; accessRequestId?: string; inflightOnly?: boolean | string },
    offline: boolean
): Promise<ResolvedPreventiveSodCheckInput> {
    const accessRequestId = input.accessRequestId?.trim() || undefined
    const providedIdentityId = input.identityId?.trim() || undefined
    const inflightOnly = parseInflightOnly(input.inflightOnly)

    if (!accessRequestId && !providedIdentityId) {
        throw new ConnectorError('Missing required input: identityId or accessRequestId')
    }

    if (accessRequestId) {
        if (providedIdentityId) {
            getActiveFrameworkLogger(requestId).warn(
                'preventive-sod-check: identityId ignored when accessRequestId is provided'
            )
        }

        const identityId = offline
            ? resolveIdentityIdForAccessRequestOffline(accessRequestId)
            : await resolveIdentityIdForAccessRequest(sdk.accessRequests, accessRequestId)

        if (!identityId) {
            throw new ConnectorError(`Could not resolve identity for access request: ${accessRequestId}`)
        }

        return { identityId, accessRequestId, inflightOnly }
    }

    return { identityId: providedIdentityId!, accessRequestId: undefined, inflightOnly }
}
