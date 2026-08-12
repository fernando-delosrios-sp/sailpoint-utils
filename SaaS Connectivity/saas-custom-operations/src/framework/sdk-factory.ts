import {
    AccessProfilesApi,
    AccessRequestsApi,
    AccountsApi,
    Configuration,
    CustomFormsApi,
    EntitlementsApi,
    GovernanceGroupsApi,
    IAIOutliersApi,
    IAIRecommendationsApi,
    IdentitiesApi,
    IdentityHistoryApi,
    RolesApi,
    SearchApi,
    SODPoliciesApi,
    SODViolationsApi,
    SourcesApi,
    TaskManagementApi,
} from 'sailpoint-api-client'
import { SailPointClients } from './types'

/** Experimental ISC APIs require this header. */
export const SAILPOINT_EXPERIMENTAL = 'true'

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
        entitlements: new EntitlementsApi(configuration),
        roles: new RolesApi(configuration),
        identities: new IdentitiesApi(configuration),
        tasks: new TaskManagementApi(configuration),
        governanceGroups: new GovernanceGroupsApi(configuration),
        accessRequests: new AccessRequestsApi(configuration),
        search: new SearchApi(configuration),
        sodPolicies: new SODPoliciesApi(configuration),
        sodViolations: new SODViolationsApi(configuration),
        iaiRecommendations: new IAIRecommendationsApi(configuration),
        iaiOutliers: new IAIOutliersApi(configuration),
    }
}


