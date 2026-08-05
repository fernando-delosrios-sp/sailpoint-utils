import { Response } from '@sailpoint/connector-sdk'
import {
    AccessProfilesApi,
    AccessRequestsApi,
    AccountsApi,
    EntitlementsApi,
    GovernanceGroupsApi,
    IAIOutliersApi,
    IAIRecommendationsApi,
    IdentitiesApi,
    RolesApi,
    SODPoliciesApi,
    SODViolationsApi,
} from 'sailpoint-api-client'

/** Standard fields resolved from an invoke payload: config + input. */
export interface StandardInput {
    apiUrl: string
    token: string
    requestId: string
    sourceId: string
}

/** SailPoint API clients pre-configured for ISC loopback during a custom operation. */
export interface SailPointClients {
    accounts: AccountsApi
    accessRequests: AccessRequestsApi
    accessProfiles: AccessProfilesApi
    entitlements: EntitlementsApi
    roles: RolesApi
    identities: IdentitiesApi
    governanceGroups: GovernanceGroupsApi
    sodPolicies: SODPoliciesApi
    sodViolations: SODViolationsApi
    iaiRecommendations: IAIRecommendationsApi
    iaiOutliers: IAIOutliersApi
}

/** Options for {@link PersistFn}. Verification runs by default; set verify to false to defer. */
export interface PersistOptions {
    verify?: boolean
}

/** Callback that persists operation output as a dummy account on the target source. */
export type PersistFn<TOutput extends object = Record<string, unknown>> = (
    id: string,
    attributes?: Partial<TOutput>,
    status?: string,
    options?: PersistOptions
) => Promise<void>

/** Verifies identities previously written via persist in the same invocation. */
export type VerifyPersistedFn = (ids: string[]) => Promise<void>

/** Expected attributes recorded per identity for batch verification. */
export type WriteRegistry = Map<string, Record<string, string>>

/**
 * Volatile request context scoped to a single custom operation invocation.
 * Initialized automatically by {@link customOperation}.
 */
export interface RequestContext<TOutput extends object = Record<string, unknown>> {
    requestId: string
    sourceId: string
    sdk: SailPointClients
    persist: PersistFn<TOutput>
    verifyPersisted: VerifyPersistedFn
    /** SDK response object for sending command output back to ISC. */
    res: Response<any>
}

export interface PersistDependencies {
    sourceId: string
    createAccount: (attributes: Record<string, string>) => Promise<unknown>
    readAccount: (id: string) => Promise<Record<string, string> | undefined>
    /** Override for tests to avoid real delays during retry loops. */
    sleep?: (ms: number) => Promise<void>
}

