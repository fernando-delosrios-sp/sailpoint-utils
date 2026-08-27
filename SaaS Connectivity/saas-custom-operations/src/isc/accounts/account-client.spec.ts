import { AccountsApi } from 'sailpoint-api-client'
import { describe, expect, it, vi } from 'vitest'
import { createAccount, getAccount, listAccounts, putAccount } from './account-client'

describe('isc/accounts account-client', () => {
    it('getAccount calls getAccountV1 with the account id', async () => {
        const getAccountV1 = vi.fn().mockResolvedValue({
            data: { id: 'isc-account-1', sourceId: 'source-1', attributes: { id: 'req-001' } },
        })
        const accounts = { getAccountV1 } as unknown as AccountsApi

        const account = await getAccount(accounts, 'isc-account-1')

        expect(getAccountV1).toHaveBeenCalledWith({ id: 'isc-account-1' })
        expect(account?.id).toBe('isc-account-1')
    })

    it('listAccounts calls listAccountsV1 with caller filters', async () => {
        const listAccountsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'isc-account-1', sourceId: 'source-1' }],
        })
        const accounts = { listAccountsV1 } as unknown as AccountsApi

        const page = await listAccounts(accounts, {
            filters: 'sourceId eq "source-1"',
            limit: 10,
            detailLevel: 'FULL',
        })

        expect(listAccountsV1).toHaveBeenCalledWith({
            filters: 'sourceId eq "source-1"',
            limit: 10,
            offset: undefined,
            detailLevel: 'FULL',
        })
        expect(page).toHaveLength(1)
    })

    it('createAccount calls createAccountV1 with caller attributes', async () => {
        const createAccountV1 = vi.fn().mockResolvedValue({ data: { id: 'task-create-1' } })
        const accounts = { createAccountV1 } as unknown as AccountsApi

        const taskId = await createAccount(accounts, { sourceId: 'source-1', id: 'req-001' })

        expect(createAccountV1).toHaveBeenCalledWith({
            accountAttributesCreate: { attributes: { sourceId: 'source-1', id: 'req-001' } },
        })
        expect(taskId).toBe('task-create-1')
    })

    it('putAccount calls putAccountV1 with caller attributes', async () => {
        const putAccountV1 = vi.fn().mockResolvedValue({ data: { id: 'task-put-1' } })
        const accounts = { putAccountV1 } as unknown as AccountsApi

        const taskId = await putAccount(accounts, 'isc-account-1', {
            sourceId: 'source-1',
            id: 'req-001',
            outcome: 'updated',
        })

        expect(putAccountV1).toHaveBeenCalledWith({
            id: 'isc-account-1',
            accountAttributes: {
                attributes: { sourceId: 'source-1', id: 'req-001', outcome: 'updated' },
            },
        })
        expect(taskId).toBe('task-put-1')
    })
})
