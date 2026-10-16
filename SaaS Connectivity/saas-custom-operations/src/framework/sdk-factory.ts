import {
    AccessProfilesApi,
    AccessRequestsApi,
    AccountsApi,
    Configuration,
    CustomFormsApi,
    EntitlementsApi,
    GovernanceGroupsApi,
    IdentityHistoryApi,
    MachineAccountsApi,
    MachineIdentitiesApi,
    RolesApi,
    SearchApi,
    SODPoliciesApi,
    SODViolationsApi,
    SourcesApi,
    TaggedObjectsApi,
    TagsApi,
    TaskManagementApi,
} from 'sailpoint-api-client'
import { DEFAULT_ISC_CONCURRENCY, installConcurrencyLimit, ConcurrentAxiosInstance } from './concurrency'
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

    const axiosInstance = configuration.axiosInstance as unknown as RetryingAxiosInstance & ConcurrentAxiosInstance

    // Throttle first, concurrency second: on 429 the concurrency slot releases before retry.
    installThrottleRetry(axiosInstance, {
        onRetry: ({ attempt, delayMs, url }) => {
            getActiveFrameworkLogger()?.warn('ISC request throttled, retrying', { attempt, delayMs, url })
        },
    })
    installConcurrencyLimit(axiosInstance, { limit: DEFAULT_ISC_CONCURRENCY })

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
        machineAccounts: new MachineAccountsApi(configuration),
        machineIdentities: new MachineIdentitiesApi(configuration),
        tags: new TagsApi(configuration),
        taggedObjects: new TaggedObjectsApi(configuration),
    }
}
