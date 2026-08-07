import { describe, expect, it, vi, afterEach } from 'vitest'
import { defineOperationSchema } from './define-operation-schema'
import { OperationSignature } from './output-schema'
import {
    clearOperationSchemaRegistry,
    registerOperationSchema,
} from './operation-schema-registry'
import { createRequestContext } from './request-context'
import { customOperation, normalizeAccessToken, parseStandardInput } from './with-custom-operation'

const testConfig = {
    apiUrl: 'https://tenant.api.identitynow.com',
    token: 'pat-token',
    sourceName: 'SaaS Custom Operations',
}

interface TestOperation extends OperationSignature {
    input: { payload?: string }
    output: { result: string }
}

describe('normalizeAccessToken', () => {
    it('strips Bearer prefix and surrounding whitespace from config.token', () => {
        expect(normalizeAccessToken('  Bearer eyJ.test.sig  ')).toBe('eyJ.test.sig')
    })
})

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

    it('throws when sourceName is missing or empty', () => {
        expect(() =>
            parseStandardInput({ apiUrl: 'https://tenant.api.identitynow.com', token: 'pat-token' }, { requestId: 'req-001' })
        ).toThrow(/Missing required config fields: sourceName/)

        expect(() =>
            parseStandardInput(
                { apiUrl: 'https://tenant.api.identitynow.com', token: 'pat-token', sourceName: '' },
                { requestId: 'req-001' }
            )
        ).toThrow(/Missing required config fields: sourceName/)
    })

    it('throws when requestId is missing from input', () => {
        expect(() => parseStandardInput(testConfig, { message: 'hello' })).toThrow(/Missing required input fields: requestId/)
    })

    it('accepts minimal input when test mode is active without config', () => {
        const { standard, operationInput } = parseStandardInput({}, { requestId: 'offline-001', message: 'hi' }, {
            testMode: true,
            configProvided: false,
        })

        expect(standard.requestId).toBe('offline-001')
        expect(standard.token).toBe('')
        expect(standard.sourceName).toBe('test-mode-local')
        expect(operationInput).toEqual({ message: 'hi' })
    })

    it('rejects partial config when config is provided in test mode', () => {
        expect(() =>
            parseStandardInput({ testMode: true }, { requestId: 'req-001' }, { testMode: true, configProvided: true })
        ).toThrow(/Missing required config fields/)
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

    it('resolves operationSchema from registry when operationSchema option is omitted', async () => {
        clearOperationSchemaRegistry()
        registerOperationSchema(
            'custom:example',
            defineOperationSchema({ summary: 'string', step: { type: 'string', optional: true } })
        )

        const res = { send: vi.fn() }
        const handler = vi.fn(async (ctx) => {
            expect(ctx.operationSchema?.outputFields.map((field) => field.name).sort()).toEqual(['step', 'summary'])
        })
        const wrapped = customOperation<TestOperation>(handler, {
            config: testConfig,
            sourceId: 'source-123',
        })

        await wrapped({ commandType: 'custom:example' } as any, { requestId: 'req-001' }, res as any)

        expect(handler).toHaveBeenCalled()
    })

    it('prefers explicit operationSchema over registry lookup', async () => {
        clearOperationSchemaRegistry()
        registerOperationSchema('custom:test', defineOperationSchema({ registry: 'string' }))

        const res = { send: vi.fn() }
        const explicitSchema = defineOperationSchema({ explicit: 'string' })
        const handler = vi.fn(async (ctx) => {
            expect(ctx.operationSchema?.outputFields.map((field) => field.name)).toEqual(['explicit'])
        })
        const wrapped = customOperation<TestOperation>(handler, {
            config: testConfig,
            sourceId: 'source-123',
            operationSchema: explicitSchema,
        })

        await wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-001' }, res as any)

        expect(handler).toHaveBeenCalled()
    })

    it('leaves operationSchema undefined for manual ops without registry entry or explicit option', async () => {
        clearOperationSchemaRegistry()
        const res = { send: vi.fn() }
        const handler = vi.fn(async (ctx) => {
            expect(ctx.operationSchema).toBeUndefined()
        })
        const wrapped = customOperation<TestOperation>(handler, {
            config: testConfig,
            sourceId: 'source-123',
        })

        await wrapped({ commandType: 'custom:manual' } as any, { requestId: 'req-001' }, res as any)

        expect(handler).toHaveBeenCalled()
    })
})

describe('customOperation test mode', () => {
    const originalEnv = process.env.SPCX_TEST_MODE

    afterEach(() => {
        if (originalEnv === undefined) {
            delete process.env.SPCX_TEST_MODE
        } else {
            process.env.SPCX_TEST_MODE = originalEnv
        }
    })

    it('activates test mode via SPCX_TEST_MODE when no config is provided', async () => {
        process.env.SPCX_TEST_MODE = '1'
        const lines: string[] = []
        const logSpy = vi.spyOn(console, 'log').mockImplementation((...args) => {
            lines.push(args.map(String).join(' '))
        })
        const res = { send: vi.fn() }
        const wrapped = customOperation<TestOperation>(async () => {})

        await wrapped({ commandType: 'custom:test' } as any, { requestId: 'env-001' }, res as any)

        expect(lines.some((line) => line.includes('[test-mode] active'))).toBe(true)
        expect(lines.some((line) => line.includes('no config — skipping ISC'))).toBe(true)
        logSpy.mockRestore()
    })

    it('rejects partial config with missing connection fields', async () => {
        const res = { send: vi.fn() }
        const wrapped = customOperation<TestOperation>(async () => {}, {
            config: { testMode: true },
        })

        await expect(
            wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-001' }, res as any)
        ).rejects.toThrow(/Missing required config fields/)
    })

    it('rejects when ISC status check fails with token present', async () => {
        const res = { send: vi.fn() }
        const sourcesApi = {
            listSourcesV1: vi.fn().mockRejectedValue(new Error('Unauthorized')),
            createSourceV1: vi.fn(),
        }
        const wrapped = customOperation<TestOperation>(async () => {}, {
            config: { ...testConfig, testMode: true },
            sdk: { sources: sourcesApi as any, accounts: { createAccountV1: vi.fn(), listAccountsV1: vi.fn() } as any },
        })

        await expect(
            wrapped(
                { commandType: 'custom:test', config: { ...testConfig, testMode: true } } as any,
                { requestId: 'req-001' },
                res as any
            )
        ).rejects.toThrow('Unauthorized')
    })

    it('skips all ISC API calls when no config is provided', async () => {
        process.env.SPCX_TEST_MODE = '1'
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
        const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const res = { send: vi.fn() }
        const sourcesApi = { listSourcesV1: vi.fn(), createSourceV1: vi.fn() }
        const accountsApi = { createAccountV1: vi.fn(), listAccountsV1: vi.fn() }
        const handler = vi.fn(async (ctx) => {
            await ctx.persist('req-001', { result: 'ok' })
            ctx.res.send({ status: 'success' })
        })
        const wrapped = customOperation<TestOperation>(handler, {
            sdk: { sources: sourcesApi as any, accounts: accountsApi as any },
        })

        await wrapped({ commandType: 'custom:test' } as any, { requestId: 'offline-001' }, res as any)

        expect(sourcesApi.listSourcesV1).not.toHaveBeenCalled()
        expect(accountsApi.createAccountV1).not.toHaveBeenCalled()
        expect(handler).toHaveBeenCalledWith(
            expect.objectContaining({ sourceId: 'test-mode-local' }),
            {}
        )
        expect(res.send).toHaveBeenCalledWith({ status: 'success' })
        logSpy.mockRestore()
        warnSpy.mockRestore()
    })

    it('checks ISC status and resolves source read-only when token is provided', async () => {
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
        const res = { send: vi.fn() }
        const sourcesApi = {
            listSourcesV1: vi
                .fn()
                .mockResolvedValueOnce({ data: [] })
                .mockResolvedValueOnce({ data: [{ id: 'source-readonly', name: 'SaaS Custom Operations' }] }),
            createSourceV1: vi.fn(),
        }
        const accountsApi = { createAccountV1: vi.fn(), listAccountsV1: vi.fn() }
        const handler = vi.fn(async () => {})
        const wrapped = customOperation<TestOperation>(handler, {
            config: { ...testConfig, testMode: true },
            sdk: { sources: sourcesApi as any, accounts: accountsApi as any },
        })

        await wrapped({ commandType: 'custom:test', config: { ...testConfig, testMode: true } } as any, { requestId: 'req-001' }, res as any)

        expect(sourcesApi.listSourcesV1).toHaveBeenCalledWith({ limit: 1 })
        expect(sourcesApi.createSourceV1).not.toHaveBeenCalled()
        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ sourceId: 'source-readonly' }), {})
        expect(logSpy.mock.calls.some((call) => String(call[0]).includes('ISC status check succeeded'))).toBe(true)
        logSpy.mockRestore()
    })

    it('uses placeholder sourceId when token provided but source not found', async () => {
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
        const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const res = { send: vi.fn() }
        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceV1: vi.fn(),
        }
        const handler = vi.fn(async () => {})
        const wrapped = customOperation<TestOperation>(handler, {
            config: { ...testConfig, testMode: true },
            sdk: { sources: sourcesApi as any, accounts: { createAccountV1: vi.fn(), listAccountsV1: vi.fn() } as any },
        })

        await wrapped({ commandType: 'custom:test', config: { ...testConfig, testMode: true } } as any, { requestId: 'req-001' }, res as any)

        expect(sourcesApi.createSourceV1).not.toHaveBeenCalled()
        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ sourceId: 'test-mode-local' }), {})
        expect(warnSpy.mock.calls.some((call) => String(call[0]).includes('not found'))).toBe(true)
        logSpy.mockRestore()
        warnSpy.mockRestore()
    })

    it('logs test mode startup, inhibited persist, and summary', async () => {
        process.env.SPCX_TEST_MODE = '1'
        const lines: string[] = []
        const logSpy = vi.spyOn(console, 'log').mockImplementation((...args) => {
            lines.push(args.map(String).join(' '))
        })
        const res = { send: vi.fn() }
        const handler = vi.fn(async (ctx) => {
            await ctx.persist('req-001', { result: 'done' })
        })
        const wrapped = customOperation<TestOperation>(handler)

        await wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-001' }, res as any)

        expect(lines.some((line) => line.includes('[test-mode] active'))).toBe(true)
        expect(lines.some((line) => line.includes('[test-mode] inhibited persist'))).toBe(true)
        expect(lines.some((line) => line.includes('[test-mode] completed') && line.includes('inhibitedPersists=1'))).toBe(
            true
        )
        logSpy.mockRestore()
    })

    it('does not log token values in test mode output', async () => {
        const lines: string[] = []
        const logSpy = vi.spyOn(console, 'log').mockImplementation((...args) => {
            lines.push(args.map(String).join(' '))
        })
        const res = { send: vi.fn() }
        const secretToken = 'super-secret-token-value'
        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceV1: vi.fn(),
        }
        const wrapped = customOperation<TestOperation>(async () => {}, {
            config: { ...testConfig, testMode: true, token: secretToken },
            sdk: { sources: sourcesApi as any, accounts: { createAccountV1: vi.fn(), listAccountsV1: vi.fn() } as any },
        })

        await wrapped(
            { commandType: 'custom:test', config: { ...testConfig, testMode: true, token: secretToken } } as any,
            { requestId: 'req-001' },
            res as any
        )

        for (const line of lines) {
            expect(line).not.toContain(secretToken)
        }
        logSpy.mockRestore()
    })

    it('invokes res.send normally in test mode', async () => {
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }
        const wrapped = customOperation<TestOperation>(async (ctx) => {
            ctx.res.send({ status: 'success', outcome: 'ok' })
        })

        await wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-001' }, res as any)

        expect(res.send).toHaveBeenCalledWith({ status: 'success', outcome: 'ok' })
    })
})
