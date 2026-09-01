import { describe, expect, it, vi } from 'vitest'
import { Response } from '@sailpoint/connector-sdk'
import { createFrameworkLogger } from './logger'
import { createRequestContext } from './request-context'

describe('operation response envelope via ctx.respond', () => {
    const input = {
        apiUrl: 'https://tenant.api.identitynow.com',
        token: 'pat-token',
        requestId: 'req-001',
        sourceName: 'SaaS Custom Operations',
    }

    function stubSdk() {
        return {
            accounts: {
                createAccountV1: vi.fn().mockResolvedValue({ data: { id: 'task-1' } }),
                listAccountsV1: vi.fn().mockResolvedValue({ data: [] }),
                getAccountV1: vi.fn(),
                putAccountV1: vi.fn(),
            } as never,
            sources: {} as never,
            forms: {} as never,
            identityHistory: {} as never,
            accessProfiles: {} as never,
            roles: {} as never,
            tasks: {
                getTaskStatusV1: vi.fn().mockResolvedValue({
                    data: {
                        completed: '2026-08-11T10:00:00Z',
                        completionStatus: 'SUCCESS',
                        target: { id: 'isc-1' },
                        messages: [],
                    },
                }),
            } as never,
            governanceGroups: {} as never,
            accessRequests: {} as never,
            search: {} as never,
            sodPolicies: {} as never,
            sodViolations: {} as never,
        }
    }

    it('emits name, status, responses, and summary on res.send', async () => {
        const send = vi.fn()
        const ctx = createRequestContext<{ formUrl: string }, { 'items-scanned': number }>(
            input,
            { send } as unknown as Response<any>,
            { sourceId: 'source-1', command: 'custom:example', testMode: true, sdk: stubSdk() }
        )

        await ctx.persist('req:child-a', { formUrl: 'https://form.example/a' })
        ctx.respond({ 'items-scanned': 50 })

        expect(send).toHaveBeenCalledWith({
            name: 'custom:example',
            status: 'success',
            responses: ['req:child-a'],
            summary: { 'items-scanned': 50 },
        })
    })

    it('lists all persisted native ids from the write registry in responses', async () => {
        const send = vi.fn()
        const ctx = createRequestContext(input, { send } as unknown as Response<any>, {
            sourceId: 'source-1',
            command: 'custom:example',
            testMode: true,
            sdk: stubSdk(),
        })

        await ctx.persist('req:child-a', { outcome: 'a' })
        await ctx.persist('req:child-b', { outcome: 'b' })
        ctx.respond({ ok: true })

        expect(send.mock.calls[0]?.[0].responses).toEqual(['req:child-a', 'req:child-b'])
    })

    it('defaults status to success when omitted', () => {
        const send = vi.fn()
        const ctx = createRequestContext(input, { send } as unknown as Response<any>, {
            sourceId: 'source-1',
            command: 'custom:example',
            testMode: true,
            sdk: stubSdk(),
        })

        ctx.respond({ ok: true })

        expect(send).toHaveBeenCalledWith(expect.objectContaining({ status: 'success' }))
    })

    it('uses an explicit status when provided', () => {
        const send = vi.fn()
        const ctx = createRequestContext(input, { send } as unknown as Response<any>, {
            sourceId: 'source-1',
            command: 'custom:example',
            testMode: true,
            sdk: stubSdk(),
        })

        ctx.respond({ ok: false }, 'error')

        expect(send).toHaveBeenCalledWith(expect.objectContaining({ status: 'error' }))
    })
})

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

    it('exposes ctx.log backed by the framework logger', () => {
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
        const logger = createFrameworkLogger({ requestId: 'req-001' })
        const ctx = createRequestContext(input, {} as Response<any>, {
            sourceId: 'source-1',
            logger,
            sdk: {
                accounts: {} as never,
                sources: {} as never,
                forms: {} as never,
                identityHistory: {} as never,
                accessProfiles: {} as never,
                roles: {} as never,
                tasks: {} as never,
            },
        })

        ctx.log.info('persist wiring check')

        expect(ctx.log).toBe(logger)
        expect(logSpy).toHaveBeenCalledWith('[req-001] persist wiring check')
        logSpy.mockRestore()
    })
})
