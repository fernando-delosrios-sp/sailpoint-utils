import { AccountsApi } from 'sailpoint-api-client'
import { ListAccountsParams } from './types'

/** Returns an account by ISC account id. */
export async function getAccount(
    accounts: AccountsApi,
    accountId: string
): Promise<{ id?: string; sourceId?: string; attributes?: unknown } | undefined> {
    const response = await accounts.getAccountV1({ id: accountId })
    return response.data
}

/** Lists accounts matching caller-supplied OData filters and pagination. */
export async function listAccounts(accounts: AccountsApi, params: ListAccountsParams = {}) {
    const response = await accounts.listAccountsV1({
        filters: params.filters,
        limit: params.limit,
        offset: params.offset,
        detailLevel: params.detailLevel as never,
    })
    return response.data ?? []
}

/** Creates an account from caller-supplied attributes; returns provisioning task id when present. */
export async function createAccount(
    accounts: AccountsApi,
    attributes: { sourceId: string; [key: string]: unknown }
): Promise<string | undefined> {
    const response = await accounts.createAccountV1({
        accountAttributesCreate: { attributes },
    })
    return response.data?.id
}

/** Updates an account from caller-supplied attributes; returns provisioning task id when present. */
export async function putAccount(
    accounts: AccountsApi,
    accountId: string,
    attributes: { sourceId: string; [key: string]: unknown }
): Promise<string | undefined> {
    const response = await accounts.putAccountV1({
        id: accountId,
        accountAttributes: { attributes },
    })
    return response.data?.id
}
