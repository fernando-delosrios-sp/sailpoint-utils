import { AccountsApi, Configuration, SourcesApi } from 'sailpoint-api-client'
import { SailPointClients } from './types'

/** Builds pre-configured SailPoint API clients for ISC loopback operations. */
export function createSailPointClients(apiUrl: string, token: string): SailPointClients {
    const configuration = new Configuration({
        baseurl: apiUrl,
        accessToken: token,
    })

    return {
        accounts: new AccountsApi(configuration),
        sources: new SourcesApi(configuration),
    }
}
