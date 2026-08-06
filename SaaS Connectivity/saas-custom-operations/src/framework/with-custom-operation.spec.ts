import { describe, expect, it, vi } from 'vitest'
import { OperationSignature } from './output-schema'
import { createRequestContext } from './request-context'
import { customOperation, parseStandardInput } from './with-custom-operation'

const testConfig = {
    apiUrl: 'https://tenant.api.identitynow.com',
    token: 'pat-token',
    sourceName: 'SaaS Custom Operations',
}

interface TestOperation extends OperationSignature {
    input: { payload?: string }
    output: { result: string }
}

describe('parseStandardInput', () => {
    it('parses apiUrl, token, and sourceName from config and requestId from input', () => {
        const { standard, operationInput } = parseStandardInput(testConfig, {
            requestId: 'req-001',
            message: 'hello',
        })

        expect(standard).toEqual({
            apiUrl: 'https://tenant.api.identitynow.com',
            token: 'pat-token',
            requestId: 'req-001',
            sourceName: 'SaaS Custom Operations',
        })
        expect(operationInput).toEqual({ message: 'hello' })
    })

    it('throws when required config fields are missing', () => {
        expect(() =>
            parseStandardInput({ token: 'pat-token', sourceName: 'SaaS Custom Operations' }, { requestId: 'req-001' })
        ).toThrow(/Missing required config fields: apiUrl/)
    })

    it('throws when requestId is missing from input', () => {
        expect(() => parseStandardInput(testConfig, { message: 'hello' })).toThrow(/Missing required input fields: requestId/)
    })
})

describe('createRequestContext', () => {
    it('initializes independent contexts per invocation input', () => {
        const accountsApi = {
            createAccountV1: vi.fn().mockResolvedValue({}),
            listAccountsV1: vi.fn().mockResolvedValue({ data: [] }),
        } as any
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            updateSourceSchemaV1: vi.fn(),
        } as any
        const res = { send: vi.fn() } as any

        const first = createRequestContext<{ result: string }>(
            {
                apiUrl: 'https://a.example.com',
                token: 'token-a',
                requestId: 'req-a',
                sourceName: 'Source A',
            },
            res,
            { accountsApi, sourcesApi, sourceId: 'source-a' }
        )

        const second = createRequestContext<{ result: string }>(
            {
                apiUrl: 'https://b.example.com',
                token: 'token-b',
                requestId: 'req-b',
                sourceName: 'Source B',
            },
            res,
            { accountsApi, sourcesApi, sourceId: 'source-b' }
        )

        expect(first.requestId).toBe('req-a')
        expect(second.requestId).toBe('req-b')
        expect(first.sourceName).toBe('Source A')
        expect(second.sourceName).toBe('Source B')
        expect(first.sourceId).toBe('source-a')
        expect(second.sourceId).toBe('source-b')
        expect(first.res).toBe(res)
        expect(first).not.toBe(second)
    })

    it('exposes verifyPersisted on the request context', () => {
        const accountsApi = {
            createAccountV1: vi.fn().mockResolvedValue({}),
            listAccountsV1: vi.fn().mockResolvedValue({ data: [] }),
        } as any
        const res = { send: vi.fn() } as any

        const ctx = createRequestContext<{ result: string }>(
            {
                apiUrl: 'https://a.example.com',
                token: 'token-a',
                requestId: 'req-a',
                sourceName: 'Source A',
            },
            res,
            { accountsApi, sourceId: 'source-a' }
        )

        expect(typeof ctx.verifyPersisted).toBe('function')
    })
})

describe('customOperation', () => {
    it('provides parsed standard input and res on context to the handler', async () => {
        const res = { send: vi.fn() }
        const handler = vi.fn(async (ctx) => {
            ctx.res.send({ status: 'success' })
        })
        const wrapped = customOperation<TestOperation>(handler, {
            config: testConfig,
            sourceId: 'source-123',
        })

        await wrapped(
            { commandType: 'custom:test' } as any,
            {
                requestId: 'req-001',
                payload: 'data',
            },
            res as any
        )

        expect(handler).toHaveBeenCalledWith(
            expect.objectContaining({
                requestId: 'req-001',
                sourceName: 'SaaS Custom Operations',
                sourceId: 'source-123',
                res,
            }),
            { payload: 'data' }
        )
        expect(res.send).toHaveBeenCalledWith({ status: 'success' })
    })

    it('resolves source by name when sourceId is not provided', async () => {
        const res = { send: vi.fn() }
        const handler = vi.fn(async () => {})
        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({ data: [{ id: 'resolved-id', name: 'SaaS Custom Operations' }] }),
        } as any
        const wrapped = customOperation<TestOperation>(handler, {
            config: testConfig,
            sdk: {
                sources: sourcesApi,
                accounts: { createAccountV1: vi.fn(), listAccountsV1: vi.fn() },
            } as any,
        })

        await wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-001' }, res as any)

        expect(sourcesApi.listSourcesV1).toHaveBeenCalled()
        expect(handler).toHaveBeenCalledWith(
            expect.objectContaining({ sourceId: 'resolved-id', sourceName: 'SaaS Custom Operations' }),
            {}
        )
    })
})
