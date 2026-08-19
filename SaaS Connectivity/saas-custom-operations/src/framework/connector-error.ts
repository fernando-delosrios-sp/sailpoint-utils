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
    if (isRecord(error) && typeof error.message === 'string') {
        return error.message
    }
    return String(error)
}

function extractResponseData(error: unknown): unknown {
    if (!isRecord(error)) {
        return undefined
    }

    const data = error.data ?? (isRecord(error.response) ? error.response.data : undefined)
    if (data === undefined || data === null) {
        return undefined
    }

    return data
}

/**
 * Builds sanitized log detail for operator diagnostics.
 * Includes HTTP status and ISC response bodies for operators; {@link createFrameworkLogger} redacts
 * sensitive fields before emission. Use with `ctx.log.error` — not for workflow-visible messages.
 */
export function buildErrorLogDetail(err: unknown): Record<string, unknown> {
    if (err instanceof ConnectorError) {
        return { message: err.message, type: err.type }
    }

    const detail: Record<string, unknown> = {
        message: extractMessage(err),
    }

    const status = extractHttpStatus(err)
    if (status !== undefined) {
        detail.status = status
    }

    const responseData = extractResponseData(err)
    if (responseData !== undefined) {
        detail.responseData = responseData
    }

    if (err instanceof PersistVerificationError) {
        detail.identity = err.identity
    }

    return detail
}

/**
 * Converts unknown errors into {@link ConnectorError} for ISC platform signaling.
 * Caller-visible messages use the stable error prefix plus HTTP status when available; raw ISC API
 * response bodies are omitted from the message and should be logged via {@link buildErrorLogDetail}.
 */
export function toConnectorError(err: unknown, context?: string): ConnectorError {
    if (err instanceof ConnectorError) {
        return err
    }

    const message = extractMessage(err)
    const prefix = context ? `${context}: ` : ''
    const status = extractHttpStatus(err)
    const type = status === 404 ? ConnectorErrorType.NotFound : ConnectorErrorType.Generic
    const statusSuffix = status !== undefined ? ` (HTTP ${status})` : ''

    return new ConnectorError(`${prefix}${message}${statusSuffix}`, type)
}
