import { ConnectorError, Response } from '@sailpoint/connector-sdk'
import { AccountsApi, CustomFormsApi, SourcesApi } from 'sailpoint-api-client'
import { createPersist, createVerifyPersisted } from './persist-result'
import { createSailPointClients } from './sdk-factory'
import { ensureSourceSchema } from './source-provisioning'
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
        createAccount: async (attributes) => {
            await accountsClient.createAccountV1({
                accountAttributesCreate: {
                    attributes: attributes as { sourceId: string; [key: string]: unknown },
                },
            })
        },
        readAccount: async (id) => {
            const response = await accountsClient.listAccountsV1({
                filters: `nativeIdentity eq "${id}" and sourceId eq "${sourceId}"`,
            })
            const account = response.data?.[0]
            return account?.attributes as Record<string, unknown> | undefined
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
        createFormDefinitionV1: async () => ({ data: { id: 'offline-form-def' } }),
        createFormInstanceV1: async () => ({
            data: { standAloneFormUrl: 'https://offline.example.com/form/offline-instance' },
        }),
    }
    return {
        accounts: { createAccountV1: stub, listAccountsV1: stub } as unknown as AccountsApi,
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
    }
}
