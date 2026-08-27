import { ConnectorError } from '@sailpoint/connector-sdk'

export interface ConnectionFields {
    apiUrl: string
    token: string
}

function isConnectionFieldPresent(value: string | undefined | null): boolean {
    return value != null && String(value).trim() !== ''
}

/**
 * Determines whether an invocation uses offline ISC stubs.
 *
 * Returns `true` when both `apiUrl` and `token` are absent or blank (config-less / fixture runs).
 * Returns `false` when both fields are present (live ISC clients).
 * Throws {@link ConnectorError} when exactly one field is present so partial config cannot silently
 * flip between offline stubs and live API calls.
 */
export function isOfflineContext(fields: ConnectionFields): boolean {
    const hasApiUrl = isConnectionFieldPresent(fields.apiUrl)
    const hasToken = isConnectionFieldPresent(fields.token)

    if (!hasApiUrl && !hasToken) {
        return true
    }
    if (hasApiUrl && hasToken) {
        return false
    }
    throw new ConnectorError(
        'Incomplete connection config: apiUrl and token must both be provided or both omitted'
    )
}
