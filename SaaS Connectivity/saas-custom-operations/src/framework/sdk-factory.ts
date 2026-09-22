import {
    AccessProfilesApi,
    AccessRequestsApi,
    AccountsApi,
    Configuration,
    CustomFormsApi,
    EntitlementsApi,
    GovernanceGroupsApi,
    IdentityHistoryApi,
    RolesApi,
    SearchApi,
    SODPoliciesApi,
    SODViolationsApi,
    SourcesApi,
    TaskManagementApi,
} from 'sailpoint-api-client'
import { getActiveFrameworkLogger } from './logger'
import { installThrottleRetry, RetryingAxiosInstance } from './throttle-retry'
import { SailPointClients } from './types'

/** Builds pre-configured SailPoint API clients for ISC loopback operations. */
export function createSailPointClients(apiUrl: string, token: string): SailPointClients {
    const configuration = new Configuration({
        baseurl: apiUrl,
        accessToken: token,
    })
    configuration.experimental = true

    installThrottleRetry(configuration.axiosInstance as unknown as RetryingAxiosInstance, {
        onRetry: ({ attempt, delayMs, url }) => {
            getActiveFrameworkLogger()?.warn('ISC request throttled, retrying', { attempt, delayMs, url })
        },
    })

    return {
        accounts: new AccountsApi(configuration),
        sources: new SourcesApi(configuration),
        forms: new CustomFormsApi(configuration),
        identityHistory: new IdentityHistoryApi(configuration),
        accessProfiles: new AccessProfilesApi(configuration),
        entitlements: new EntitlementsApi(configuration),
        roles: new RolesApi(configuration),
        tasks: new TaskManagementApi(configuration),
        governanceGroups: new GovernanceGroupsApi(configuration),
        accessRequests: new AccessRequestsApi(configuration),
        search: new SearchApi(configuration),
        sodPolicies: new SODPoliciesApi(configuration),
        sodViolations: new SODViolationsApi(configuration),
    }
}


