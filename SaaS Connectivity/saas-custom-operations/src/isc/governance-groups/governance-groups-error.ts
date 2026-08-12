import { ConnectorError } from '@sailpoint/connector-sdk'

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

function extractStatus(error: unknown): number | undefined {
    if (!isRecord(error)) {
        return undefined
    }

    if (typeof error.status === 'number') {
        return error.status
    }

    if (isRecord(error.response) && typeof error.response.status === 'number') {
        return error.response.status
    }

    return undefined
}

/** Maps GovernanceGroupsApi failures into ConnectorError with HTTP status when available. */
export function toGovernanceGroupsConnectorError(action: string, error: unknown): ConnectorError {
    const status = extractStatus(error)
    const statusSuffix = status !== undefined ? ` with status ${status}` : ''
    const detail = error instanceof Error ? error.message : String(error)
    return new ConnectorError(`${action}${statusSuffix}: ${detail}`)
}
