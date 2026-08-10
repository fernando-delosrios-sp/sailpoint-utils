import { AccountsApi, AccessProfilesApi, Configuration, CustomFormsApi, IdentityHistoryApi, RolesApi, SourcesApi } from 'sailpoint-api-client'
import { SailPointClients } from './types'

/** Builds pre-configured SailPoint API clients for ISC loopback operations. */
export function createSailPointClients(apiUrl: string, token: string): SailPointClients {
    const configuration = new Configuration({
        baseurl: apiUrl,
        accessToken: token,
    })
    configuration.experimental = true

    return {
        accounts: new AccountsApi(configuration),
        sources: new SourcesApi(configuration),
        forms: new CustomFormsApi(configuration),
        identityHistory: new IdentityHistoryApi(configuration),
        accessProfiles: new AccessProfilesApi(configuration),
        roles: new RolesApi(configuration),
    }
}


