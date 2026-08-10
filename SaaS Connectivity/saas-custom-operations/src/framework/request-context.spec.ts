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
        const createAccountV1 = vi.fn().mockResolvedValue({})
        const putAccountV1 = vi.fn().mockResolvedValue({})
        const listAccountsV1 = vi.fn().mockResolvedValue({ data: [] })

        const ctx = createRequestContext(input, {} as Response<any>, {
            sourceId: 'source-1',
            sdk: {
                accounts: { createAccountV1, putAccountV1, listAccountsV1 } as never,
                sources: {} as never,
                forms: {} as never,
                identityHistory: {} as never,
                accessProfiles: {} as never,
                roles: {} as never,
            },
        })

        await ctx.persist('req-001', { outcome: 'new' }, undefined, { verify: false })

        expect(createAccountV1).toHaveBeenCalled()
        expect(putAccountV1).not.toHaveBeenCalled()
    })

    it('updates account via putAccountV1 when native identity exists', async () => {
        const createAccountV1 = vi.fn().mockResolvedValue({})
        const putAccountV1 = vi.fn().mockResolvedValue({})
        const listAccountsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'isc-account-1', attributes: { id: 'req-001', outcome: 'old' } }],
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
