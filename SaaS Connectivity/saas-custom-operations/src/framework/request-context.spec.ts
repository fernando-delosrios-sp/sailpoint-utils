import { describe, expect, it, vi } from 'vitest'
import { Response } from '@sailpoint/connector-sdk'
import { createRequestContext } from './request-context'

describe('createRequestContext persist wiring', () => {
    const input = {
        apiUrl: 'https://tenant.api.identitynow.com',
        token: 'pat-token',
        requestId: 'req-001',
        sourceName: 'SaaS Custom Operations',
    }

    it('creates account when native identity is absent', async () => {
        const createAccountV1 = vi.fn().mockResolvedValue({ data: { id: 'task-create-1' } })
        const deleteAccountAsyncV1 = vi.fn().mockResolvedValue({})
        const getAccountV1 = vi.fn().mockResolvedValue({
            data: { id: 'isc-account-new', sourceId: 'source-1', attributes: { id: 'req-001', outcome: 'new' } },
        })
        const listAccountsV1 = vi.fn().mockResolvedValue({ data: [] })
        const getTaskStatusV1 = vi.fn().mockResolvedValue({
            data: {
                completed: '2026-08-11T10:00:00Z',
                completionStatus: 'SUCCESS',
                target: { id: 'isc-account-new' },
                messages: [],
            },
        })

        const ctx = createRequestContext(input, {} as Response<any>, {
            sourceId: 'source-1',
            sdk: {
                accounts: { createAccountV1, deleteAccountAsyncV1, listAccountsV1, getAccountV1 } as never,
                sources: {} as never,
                forms: {} as never,
                identityHistory: {} as never,
                accessProfiles: {} as never,
                roles: {} as never,
                tasks: { getTaskStatusV1 } as never,
            },
        })

        await ctx.persist('req-001', { outcome: 'new' }, undefined, { verify: false })

        expect(createAccountV1).toHaveBeenCalled()
        expect(deleteAccountAsyncV1).not.toHaveBeenCalled()
    })

    it('updates account via putAccountV1 when native identity exists', async () => {
        const createAccountV1 = vi.fn().mockResolvedValue({})
        const putAccountV1 = vi.fn().mockResolvedValue({})
        const listAccountsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'isc-account-1', sourceId: 'source-1', attributes: { id: 'req-001', outcome: 'old' } }],
        })

        const ctx = createRequestContext(input, {} as Response<any>, {
            sourceId: 'source-1',
            sdk: {
                accounts: { createAccountV1, putAccountV1, listAccountsV1 } as never,
                sources: {} as never,
                forms: {} as never,
                identityHistory: {} as never,
                accessProfiles: {} as never,
                roles: {} as never,
                tasks: { getTaskStatusV1: vi.fn() } as never,
            },
        })

        await ctx.persist('req-001', { outcome: 'updated' }, undefined, { verify: false })

        expect(putAccountV1).toHaveBeenCalledWith(
            expect.objectContaining({
                id: 'isc-account-1',
                accountAttributes: expect.objectContaining({
                    attributes: expect.objectContaining({ outcome: 'updated' }),
                }),
            })
        )
        expect(createAccountV1).not.toHaveBeenCalled()
    })
})
