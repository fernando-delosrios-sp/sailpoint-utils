import { ConnectorError } from '@sailpoint/connector-sdk'

export const EXPERIMENTAL_HEADER = 'X-SailPoint-Experimental'

export interface IscClientConfig {
    apiUrl: string
    token: string
    fetchFn?: typeof fetch
}

function normalizeApiUrl(apiUrl: string): string {
    return apiUrl.replace(/\/$/, '')
}

export async function iscGet<T>(
    config: IscClientConfig,
    path: string,
    options?: { experimental?: boolean }
): Promise<T> {
    const fetchFn = config.fetchFn ?? fetch
    const url = `${normalizeApiUrl(config.apiUrl)}${path}`
    const headers: Record<string, string> = {
        Authorization: `Bearer ${config.token}`,
        Accept: 'application/json',
    }
    if (options?.experimental) {
        headers[EXPERIMENTAL_HEADER] = 'true'
    }

    const response = await fetchFn(url, {
        method: 'GET',
        headers,
    })

    if (!response.ok) {
        throw new ConnectorError(`ISC API ${path} failed with status ${response.status}`)
    }

    return (await response.json()) as T
}
