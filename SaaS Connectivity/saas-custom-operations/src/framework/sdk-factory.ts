import {
    AccessProfilesApi,
    AccessRequestsApi,
    AccountsApi,
    Configuration,
    EntitlementsApi,
    GovernanceGroupsApi,
    IAIOutliersApi,
    IAIRecommendationsApi,
    IdentitiesApi,
    RolesApi,
    SODPoliciesApi,
    SODViolationsApi,
} from 'sailpoint-api-client'
import { SailPointClients } from './types'

/** Builds pre-configured SailPoint API clients for ISC loopback operations. */
export function createSailPointClients(apiUrl: string, token: string): SailPointClients {
    const configuration = new Configuration({
        baseurl: apiUrl,
        accessToken: token,
    })

    return {
        accounts: new AccountsApi(configuration),
        accessRequests: new AccessRequestsApi(configuration),
        accessProfiles: new AccessProfilesApi(configuration),
        entitlements: new EntitlementsApi(configuration),
        roles: new RolesApi(configuration),
        identities: new IdentitiesApi(configuration),
        governanceGroups: new GovernanceGroupsApi(configuration),
        sodPolicies: new SODPoliciesApi(configuration),
        sodViolations: new SODViolationsApi(configuration),
        iaiRecommendations: new IAIRecommendationsApi(configuration),
        iaiOutliers: new IAIOutliersApi(configuration),
    }
}

/** Experimental ISC APIs require this header. */
export const SAILPOINT_EXPERIMENTAL = 'true'
