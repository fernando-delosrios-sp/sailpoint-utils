import { Response } from '@sailpoint/connector-sdk'
import { AccountsApi, SourcesApi } from 'sailpoint-api-client'
import { createPersist, createVerifyPersisted } from './persist-result'
import { createSailPointClients } from './sdk-factory'
import { ensureSourceSchema } from './source-provisioning'
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
}

/** Assembles the volatile request context for a custom operation invocation. */
export function createRequestContext<TOutput extends object>(
    input: StandardInput,
    res: Response<any>,
    deps: RequestContextDependencies = {}
): RequestContext<TOutput> {
    const sdk: SailPointClients =
        deps.sdk ??
        (deps.accountsApi || deps.sourcesApi
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

    const persist = createPersist<TOutput>(persistDeps, writeRegistry)
    const verifyPersisted = createVerifyPersisted(persistDeps, writeRegistry)

    return {
        requestId: input.requestId,
        sourceName: input.sourceName,
        sourceId,
        operationSchema: deps.operationSchema,
        sdk,
        persist,
        verifyPersisted,
        res,
    }
}
