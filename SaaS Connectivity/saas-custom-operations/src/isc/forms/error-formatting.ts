import { ConnectorError } from '@sailpoint/connector-sdk'

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

/** Maps sailpoint-api-client / axios Forms API errors into a message that includes the ISC response body. */
export function formatFormsApiError(operation: string, error: unknown): ConnectorError {
    if (isRecord(error)) {
        const status = typeof error.status === 'number' ? error.status : undefined
        const body = 'data' in error ? error.data : undefined

        if (status !== undefined || body !== undefined) {
            const statusSuffix = status !== undefined ? ` with status ${status}` : ''
            const bodyText =
                body === undefined
                    ? String(error.message ?? 'unknown error')
                    : typeof body === 'string'
                      ? body
                      : JSON.stringify(body)
            return new ConnectorError(`${operation} failed${statusSuffix}: ${bodyText}`)
        }

        if (isRecord(error.response)) {
            const axiosStatus = error.response.status
            const axiosBody = error.response.data
            const statusSuffix = typeof axiosStatus === 'number' ? ` with status ${axiosStatus}` : ''
            const bodyText =
                axiosBody === undefined
                    ? String(error.message ?? 'unknown error')
                    : typeof axiosBody === 'string'
                      ? axiosBody
                      : JSON.stringify(axiosBody)
            return new ConnectorError(`${operation} failed${statusSuffix}: ${bodyText}`)
        }
    }

    if (error instanceof Error) {
        return new ConnectorError(`${operation} failed: ${error.message}`)
    }

    return new ConnectorError(`${operation} failed: ${String(error)}`)
}

/** Wraps a Forms API call and surfaces failures as ConnectorError. */
export async function callFormsApi<T>(operation: string, fn: () => Promise<T>): Promise<T> {
    try {
        return await fn()
    } catch (error) {
        throw formatFormsApiError(operation, error)
    }
}
