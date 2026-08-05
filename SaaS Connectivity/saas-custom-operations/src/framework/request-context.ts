import { Response } from '@sailpoint/connector-sdk'
import { AccountsApi } from 'sailpoint-api-client'
import { createPersist, createVerifyPersisted } from './persist-result'
import { createSailPointClients } from './sdk-factory'
import { PersistDependencies, RequestContext, SailPointClients, StandardInput, WriteRegistry } from './types'

export interface RequestContextDependencies {
    accountsApi?: AccountsApi
    /** Full SDK override (tests). */
    sdk?: SailPointClients
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
        (deps.accountsApi
            ? { ...createSailPointClients(input.apiUrl, input.token), accounts: deps.accountsApi }
            : createSailPointClients(input.apiUrl, input.token))

    const accountsClient = sdk.accounts
    const writeRegistry: WriteRegistry = new Map()

    const persistDeps: PersistDependencies = {
        sourceId: input.sourceId,
        createAccount: async (attributes) => {
            await accountsClient.createAccountV1({
                accountAttributesCreate: {
                    attributes: attributes as { sourceId: string; [key: string]: string },
                },
            })
        },
        readAccount: async (id) => {
            const response = await accountsClient.listAccountsV1({
                filters: `nativeIdentity eq "${id}" and sourceId eq "${input.sourceId}"`,
            })
            const account = response.data?.[0]
            return account?.attributes as Record<string, string> | undefined
        },
    }

    const persist = createPersist<TOutput>(persistDeps, writeRegistry)
    const verifyPersisted = createVerifyPersisted(persistDeps, writeRegistry)

    return {
        requestId: input.requestId,
        sourceId: input.sourceId,
        sdk,
        persist,
        verifyPersisted,
        res,
    }
}
