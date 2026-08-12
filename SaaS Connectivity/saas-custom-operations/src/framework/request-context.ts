import { ConnectorError, Response } from '@sailpoint/connector-sdk'
import { AccountsApi, CustomFormsApi, SourcesApi, TaskManagementApi } from 'sailpoint-api-client'
import { createPersist, createVerifyPersisted, upsertSourceAccount, waitForAccountProvisioningTask } from './persist-result'
import { findAccountOnSource, getAccount } from '../isc/accounts'
import { createSailPointClients } from './sdk-factory'
import { ensureSourceSchema } from './result-source'
import { createTestModePersist } from './test-mode-persist'
import {
    OperationSchemaContract,
    PersistDependencies,
    RequestContext,
    SailPointClients,
    StandardInput,
    WriteRegistry,
} from './types'

export interface RequestContextDependencies {
    accountsApi?: AccountsApi
    sourcesApi?: SourcesApi
    /** Full SDK override (tests). */
    sdk?: SailPointClients
    /** Resolved source ID when source resolution is handled externally (tests). */
    sourceId?: string
    operationSchema?: OperationSchemaContract
    /** Override connector config (for tests); defaults to {@link readConfig} at runtime. */
    config?: Record<string, unknown>
    /** When true, persist and schema writes are inhibited and logged. */
    testMode?: boolean
    /** Called after each inhibited persist in test mode (summary logging). */
    onTestModePersist?: () => void
}

/** Assembles the volatile request context for a custom operation invocation. */
export function createRequestContext<TOutput extends object>(
    input: StandardInput,
    res: Response<any>,
    deps: RequestContextDependencies = {}
): RequestContext<TOutput> {
    const sdk: SailPointClients =
        deps.sdk ??
        (deps.testMode && !input.token
            ? createOfflineSdkStub()
            : deps.accountsApi || deps.sourcesApi
              ? {
                    ...createSailPointClients(input.apiUrl, input.token),
                    ...(deps.accountsApi ? { accounts: deps.accountsApi } : {}),
                    ...(deps.sourcesApi ? { sources: deps.sourcesApi } : {}),
                }
              : createSailPointClients(input.apiUrl, input.token))

    const sourceId = deps.sourceId ?? ''
    const accountsClient = sdk.accounts
    const writeRegistry: WriteRegistry = new Map()

    const persistDeps: PersistDependencies = {
        sourceId,
        operationSchema: deps.operationSchema,
        ensureSourceSchema: deps.operationSchema
            ? async (attributeKeys) => {
                  await ensureSourceSchema(
                      sdk.sources,
                      sourceId,
                      deps.operationSchema!.outputFields,
                      attributeKeys
                  )
              }
            : undefined,
        upsertAccount: async (attributes) => {
            return upsertSourceAccount(accountsClient, sourceId, attributes, {
                waitForAccountTask: (taskId) => waitForAccountProvisioningTask(sdk.tasks, taskId),
            })
        },
        readAccount: async (id) => {
            const account = await findAccountOnSource(accountsClient, sourceId, id)
            return account?.attributes
        },
        readAccountByIscId: async (iscAccountId) => {
            try {
                const account = await getAccount(accountsClient, iscAccountId)
                const attributes = account?.attributes
                return attributes ? (attributes as Record<string, unknown>) : undefined
            } catch {
                return undefined
            }
        },
    }

    const persist = deps.testMode
        ? createTestModePersist<TOutput>(
              {
                  sourceId,
                  operationSchema: deps.operationSchema,
                  onPersist: deps.onTestModePersist,
              },
              writeRegistry
          )
        : {
              persist: createPersist<TOutput>(persistDeps, writeRegistry),
              verifyPersisted: createVerifyPersisted(persistDeps, writeRegistry),
          }

    return {
        requestId: input.requestId,
        apiUrl: input.apiUrl,
        token: input.token,
        sourceName: input.sourceName,
        sourceId,
        operationSchema: deps.operationSchema,
        sdk,
        persist: persist.persist,
        verifyPersisted: persist.verifyPersisted,
        res,
    }
}

function offlineApiError(): never {
    throw new ConnectorError('ISC API is unavailable in offline test mode')
}

/** Stub SDK used when test mode runs without an access token. */
function createOfflineSdkStub(): SailPointClients {
    const stub = () => offlineApiError()
    const offlineFormsStub = {
        searchFormDefinitionsByTenantV1: async () => ({ data: { results: [{ id: 'offline-form-def' }] } }),
        getFormDefinitionByKeyV1: async () => ({
            data: { id: 'offline-form-def', description: 'Legacy offline form definition' },
        }),
        createFormDefinitionV1: async () => ({ data: { id: 'offline-form-def' } }),
        patchFormDefinitionV1: async () => ({ data: { id: 'offline-form-def' } }),
        createFormInstanceV1: async () => ({
            data: { standAloneFormUrl: 'https://offline.example.com/form/offline-instance' },
        }),
    }
    return {
        accounts: {
            createAccountV1: stub,
            listAccountsV1: stub,
            putAccountV1: stub,
            getAccountV1: stub,
            deleteAccountAsyncV1: stub,
        } as unknown as AccountsApi,
        sources: {
            listSourcesV1: stub,
            createSourceV1: stub,
            getSourceSchemasV1: stub,
            updateSourceSchemaV1: stub,
            createSourceSchemaV1: stub,
        } as unknown as SourcesApi,
        forms: offlineFormsStub as unknown as CustomFormsApi,
        identityHistory: { listIdentityAccessItemsV1: stub } as unknown as SailPointClients['identityHistory'],
        accessProfiles: { getAccessProfileEntitlementsV1: stub } as unknown as SailPointClients['accessProfiles'],
        roles: { getRoleEntitlementsV1: stub } as unknown as SailPointClients['roles'],
        tasks: { getTaskStatusV1: stub } as unknown as TaskManagementApi,
        governanceGroups: {
            listWorkgroupsV1: stub,
            listWorkgroupMembersV1: stub,
        } as unknown as SailPointClients['governanceGroups'],
        accessRequests: { listAccessRequestStatusV1: stub } as unknown as SailPointClients['accessRequests'],
        search: { searchPostV1: stub } as unknown as SailPointClients['search'],
        sodViolations: { startPredictSodViolationsV1: stub } as unknown as SailPointClients['sodViolations'],
    }
}

