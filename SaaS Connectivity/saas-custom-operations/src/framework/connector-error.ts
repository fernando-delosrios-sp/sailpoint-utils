import { ConnectorError, ConnectorErrorType } from '@sailpoint/connector-sdk'
import { PersistVerificationError } from './persist-result'

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

function extractHttpStatus(error: unknown): number | undefined {
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

function extractMessage(error: unknown): string {
    if (error instanceof Error) {
        return error.message
    }
    return String(error)
}

/** Converts unknown errors into ConnectorError for ISC platform signaling. */
export function toConnectorError(err: unknown, context?: string): ConnectorError {
    if (err instanceof ConnectorError) {
        return err
    }

    const message = extractMessage(err)
    const prefix = context ? `${context}: ` : ''
    const status = extractHttpStatus(err)
    const type = status === 404 ? ConnectorErrorType.NotFound : ConnectorErrorType.Generic
    const statusSuffix = status !== undefined ? ` (HTTP ${status})` : ''

    if (err instanceof PersistVerificationError) {
        return new ConnectorError(`${prefix}${message}${statusSuffix}`, ConnectorErrorType.Generic)
    }

    return new ConnectorError(`${prefix}${message}${statusSuffix}`, type)
}
