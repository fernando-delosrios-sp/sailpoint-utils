import { ConnectorError } from '@sailpoint/connector-sdk'
import { EXPERIMENTAL_HEADER, type IscClientConfig } from './isc-get'

function normalizeApiUrl(apiUrl: string): string {
    return apiUrl.replace(/\/$/, '')
}

export async function iscPost<T>(
    config: IscClientConfig,
    path: string,
    body: unknown,
    options?: { experimental?: boolean }
): Promise<T> {
    const fetchFn = config.fetchFn ?? fetch
    const url = `${normalizeApiUrl(config.apiUrl)}${path}`
    const headers: Record<string, string> = {
        Authorization: `Bearer ${config.token}`,
        Accept: 'application/json',
        'Content-Type': 'application/json',
    }
    if (options?.experimental) {
        headers[EXPERIMENTAL_HEADER] = 'true'
    }

    const response = await fetchFn(url, {
        method: 'POST',
        headers,
        body: JSON.stringify(body),
    })

    if (!response.ok) {
        throw new ConnectorError(`ISC API ${path} failed with status ${response.status}`)
    }

    return (await response.json()) as T
}
