import { Response } from '@sailpoint/connector-sdk'
import {
    AccessProfilesApi,
    AccessRequestsApi,
    AccountsApi,
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
import { FrameworkLogger } from './logger'
import { OperationField } from './schema-inference'

/** Standard fields resolved from an invoke payload: config + input. */
export interface StandardInput {
    apiUrl: string
    token: string
    requestId: string
    sourceName: string
}

/** Output contract for schema reconciliation during persist. */
export interface OperationSchemaContract {
    command?: string
    outputFields: OperationField[]
}

/** SailPoint API clients pre-configured for ISC loopback during a custom operation. */
export interface SailPointClients {
    accounts: AccountsApi
    sources: SourcesApi
    forms: CustomFormsApi
    identityHistory: IdentityHistoryApi
    accessProfiles: AccessProfilesApi
    entitlements: EntitlementsApi
    roles: RolesApi
    identities: IdentitiesApi
    tasks: TaskManagementApi
    governanceGroups: GovernanceGroupsApi
    accessRequests: AccessRequestsApi
    search: SearchApi
    sodPolicies: SODPoliciesApi
    sodViolations: SODViolationsApi
    iaiRecommendations: IAIRecommendationsApi
    iaiOutliers: IAIOutliersApi
}

/** Options for {@link PersistFn}. Verification runs by default; set verify to false to defer. */
export interface PersistOptions {
    verify?: boolean
    /** Human-readable outcome text (framework core attribute). Used by automatic failure persist. */
    details?: string
}

/** Callback that persists operation output as an account on the result source. */
export type PersistFn<TOutput extends object = Record<string, unknown>> = (
    id: string,
    attributes?: Partial<TOutput>,
    status?: string,
    options?: PersistOptions
) => Promise<void>

/** Verifies identities previously written via persist in the same invocation. */
export type VerifyPersistedFn = (ids: string[]) => Promise<void>

/** Expected attributes recorded per identity for batch verification. */
export type WriteRegistry = Map<string, Record<string, unknown>>

/**
 * Volatile request context scoped to a single custom operation invocation.
 * Initialized automatically by {@link customOperation}.
 *
 * `TOutput` types `ctx.persist` attributes (persisted-only `OperationSignature.output`).
 * `TSummary` types `ctx.respond` summary (optional `OperationSignature.response`).
 */
export interface RequestContext<
    TOutput extends object = Record<string, unknown>,
    TSummary extends object = Record<string, unknown>,
> {
    requestId: string
    apiUrl: string
    token: string
    sourceName: string
    sourceId: string
    operationSchema?: OperationSchemaContract
    sdk: SailPointClients
    persist: PersistFn<TOutput>
    verifyPersisted: VerifyPersistedFn
    /**
     * Builds the operation response envelope from the persist write registry and calls `res.send`.
     * Authors supply only `summary`; `name`/`status`/`responses` are framework-populated.
     */
    respond: (summary: TSummary, status?: string) => void
    /** Correlated dual-sink logger for this invocation. */
    log: FrameworkLogger
    /** SDK response object for sending command output back to ISC. */
    res: Response<any>
}

export interface PersistDependencies {
    sourceId: string
    /** Invoking custom command name (e.g. custom:example) for framework operationName attribute. */
    command?: string
    log?: FrameworkLogger
    operationSchema?: OperationSchemaContract
    ensureSourceSchema?: (attributeKeys: string[]) => Promise<void>
    /** Returns the ISC account UUID when an existing account was updated via put. */
    upsertAccount: (attributes: Record<string, unknown>) => Promise<string | undefined>
    readAccount: (id: string) => Promise<Record<string, unknown> | undefined>
    readAccountByIscId?: (iscAccountId: string) => Promise<Record<string, unknown> | undefined>
    /** Override for tests to avoid real delays during retry loops. */
    sleep?: (ms: number) => Promise<void>
}

