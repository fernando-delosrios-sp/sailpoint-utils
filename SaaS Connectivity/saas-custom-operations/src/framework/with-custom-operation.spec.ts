import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi, afterEach } from 'vitest'
import { defineOperationSchema } from './define-operation-schema'
import { OperationSignature } from './output-schema'
import {
    clearOperationSchemaRegistry,
    registerOperationSchema,
} from './operation-schema-registry'
import { createRequestContext } from './request-context'
import { clearInFlightInvocationsForTests } from './invocation-guard'
import { beginPayloadOutputCapture, endPayloadOutputCapture } from './payload-persist-collector'
import { KEEP_ALIVE_INTERVAL_MS } from './invocation-guard'
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
            putAccountV1: vi.fn().mockResolvedValue({}),
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
            putAccountV1: vi.fn().mockResolvedValue({}),
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
    afterEach(() => {
        clearInFlightInvocationsForTests()
    })

    function mockResponse() {
        return {
            send: vi.fn(),
            keepAlive: vi.fn(),
            saveState: vi.fn(),
            patchConfig: vi.fn(),
        }
    }

    it('provides parsed standard input and res on context to the handler', async () => {
        const res = mockResponse()
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
                res: expect.objectContaining({ send: expect.any(Function) }),
            }),
            { payload: 'data' }
        )
        expect(res.send).toHaveBeenCalledWith({ status: 'success' })
    })

    it('deduplicates concurrent invokes with the same command and requestId', async () => {
        let releaseHandler!: () => void
        const handlerGate = new Promise<void>((resolve) => {
            releaseHandler = resolve
        })

        const handler = vi.fn(async (ctx) => {
            await handlerGate
            ctx.res.send({ status: 'success' })
        })
        const wrapped = customOperation<TestOperation>(handler, {
            config: testConfig,
            sourceId: 'source-123',
        })

        const res1 = mockResponse()
        const res2 = mockResponse()
        const first = wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-dup' }, res1 as any)
        await Promise.resolve()
        const second = wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-dup' }, res2 as any)

        releaseHandler()
        await Promise.all([first, second])

        expect(handler).toHaveBeenCalledTimes(1)
        expect(res1.send).toHaveBeenCalledWith({ status: 'success' })
        expect(res2.send).toHaveBeenCalledWith({ status: 'success' })
    })

    it('mirrors failed outcome to duplicate concurrent invokes', async () => {
        let releaseHandler!: () => void
        const handlerGate = new Promise<void>((resolve) => {
            releaseHandler = resolve
        })

        const handler = vi.fn(async (ctx) => {
            await handlerGate
            ctx.res.send({ status: 'failed', error: 'form create failed' })
        })
        const wrapped = customOperation<TestOperation>(handler, {
            config: testConfig,
            sourceId: 'source-123',
        })

        const res1 = mockResponse()
        const res2 = mockResponse()
        const first = wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-fail-dup' }, res1 as any)
        await Promise.resolve()
        const second = wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-fail-dup' }, res2 as any)

        releaseHandler()
        await Promise.all([first, second])

        expect(handler).toHaveBeenCalledTimes(1)
        expect(res2.send).toHaveBeenCalledWith({ status: 'failed', error: 'form create failed' })
    })

    it('sends keepAlive while the handler is running', async () => {
        vi.useFakeTimers()
        try {
            const handler = vi.fn(async (ctx) => {
                await new Promise((resolve) => setTimeout(resolve, KEEP_ALIVE_INTERVAL_MS + 1_000))
                ctx.res.send({ status: 'success' })
            })
            const res = mockResponse()
            const wrapped = customOperation<TestOperation>(handler, {
                config: testConfig,
                sourceId: 'source-123',
            })

            const invocation = wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-keepalive' }, res as any)
            await vi.advanceTimersByTimeAsync(KEEP_ALIVE_INTERVAL_MS)
            expect(res.keepAlive).toHaveBeenCalled()

            await vi.advanceTimersByTimeAsync(1_000)
            await invocation
        } finally {
            vi.useRealTimers()
        }
    })

    it('passes invoking operation output fields when auto-creating result source', async () => {
        clearOperationSchemaRegistry()
        registerOperationSchema(
            'custom:example',
            defineOperationSchema({ summary: 'string', step: 'string' }, { command: 'custom:example' })
        )
        registerOperationSchema(
            'custom:other',
            defineOperationSchema({ violationId: 'string' }, { command: 'custom:other' })
        )

        const header = Buffer.from(JSON.stringify({ alg: 'none' })).toString('base64url')
        const body = Buffer.from(JSON.stringify({ identity_id: 'owner-id' })).toString('base64url')
        const token = `${header}.${body}.signature`

        const res = mockResponse()
        const handler = vi.fn(async () => {})
        const sourcesApi = {
            listSourcesV1: vi
                .fn()
                .mockResolvedValueOnce({ data: [] })
                .mockResolvedValueOnce({ data: [] }),
            createSourceV1: vi.fn().mockResolvedValue({ data: { id: 'new-source-id' } }),
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-id', name: 'account' } }),
        } as any
        const wrapped = customOperation<TestOperation>(handler, {
            config: { ...testConfig, token },
            sdk: {
                sources: sourcesApi,
                accounts: { createAccountV1: vi.fn(), putAccountV1: vi.fn(), listAccountsV1: vi.fn() },
            } as any,
        })

        await wrapped({ commandType: 'custom:example' } as any, { requestId: 'req-001' }, res as any)

        expect(sourcesApi.createSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                schema: expect.objectContaining({
                    attributes: expect.arrayContaining([
                        expect.objectContaining({ name: 'summary', type: 'STRING' }),
                        expect.objectContaining({ name: 'step', type: 'STRING' }),
                    ]),
                }),
            })
        )

        const createCall = sourcesApi.createSourceSchemaV1.mock.calls[0]?.[0]
        const attributeNames = createCall.schema.attributes.map((attr: { name: string }) => attr.name)
        expect(attributeNames).not.toContain('violationId')
        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ sourceId: 'new-source-id' }), {})
    })

    it('auto-creates core-only base schema when operationSchema is absent', async () => {
        clearOperationSchemaRegistry()

        const header = Buffer.from(JSON.stringify({ alg: 'none' })).toString('base64url')
        const body = Buffer.from(JSON.stringify({ identity_id: 'owner-id' })).toString('base64url')
        const token = `${header}.${body}.signature`

        const res = mockResponse()
        const handler = vi.fn(async (ctx) => {
            expect(ctx.operationSchema).toBeUndefined()
        })
        const sourcesApi = {
            listSourcesV1: vi
                .fn()
                .mockResolvedValueOnce({ data: [] })
                .mockResolvedValueOnce({ data: [] }),
            createSourceV1: vi.fn().mockResolvedValue({ data: { id: 'new-source-id' } }),
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-id', name: 'account' } }),
        } as any
        const wrapped = customOperation<TestOperation>(handler, {
            config: { ...testConfig, token },
            sdk: {
                sources: sourcesApi,
                accounts: { createAccountV1: vi.fn(), putAccountV1: vi.fn(), listAccountsV1: vi.fn() },
            } as any,
        })

        await wrapped({ commandType: 'custom:manual' } as any, { requestId: 'req-001' }, res as any)

        expect(sourcesApi.createSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                sourceId: 'new-source-id',
                schema: expect.objectContaining({
                    identityAttribute: 'id',
                    attributes: expect.arrayContaining([
                        expect.objectContaining({ name: 'id', type: 'STRING' }),
                        expect.objectContaining({ name: 'status', type: 'STRING' }),
                        expect.objectContaining({ name: 'date', type: 'STRING' }),
                        expect.objectContaining({ name: 'details', type: 'STRING' }),
                    ]),
                }),
            })
        )

        const createCall = sourcesApi.createSourceSchemaV1.mock.calls[0]?.[0]
        const attributeNames = createCall.schema.attributes.map((attr: { name: string }) => attr.name)
        expect(attributeNames).toEqual(['id', 'status', 'date', 'details'])
        expect(handler).toHaveBeenCalledWith(expect.objectContaining({ sourceId: 'new-source-id' }), {})
    })

    it('resolves source by name when sourceId is not provided', async () => {
        const res = mockResponse()
        const handler = vi.fn(async () => {})
        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({
                data: [{ id: 'resolved-id', name: 'SaaS Custom Operations', type: 'DelimitedFile' }],
            }),
        } as any
        const wrapped = customOperation<TestOperation>(handler, {
            config: testConfig,
            sdk: {
                sources: sourcesApi,
                accounts: { createAccountV1: vi.fn(), putAccountV1: vi.fn(), listAccountsV1: vi.fn() },
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

    it('sends status failed for persist verification failure instead of throwing', async () => {
        vi.useFakeTimers()
        try {
            const res = mockResponse()
            const upsertAttributes: Record<string, unknown>[] = []
            const accountsApi = {
                createAccountV1: vi.fn().mockImplementation(async (req: {
                    accountAttributesCreate?: { attributes?: Record<string, unknown> }
                }) => {
                    const attributes = req.accountAttributesCreate?.attributes
                    if (attributes) {
                        upsertAttributes.push(attributes)
                    }
                    return {}
                }),
                putAccountV1: vi.fn().mockResolvedValue({}),
                deleteAccountAsyncV1: vi.fn().mockResolvedValue({}),
                listAccountsV1: vi.fn().mockResolvedValue({ data: [] }),
            }
            const wrapped = customOperation<TestOperation>(
                async (ctx) => {
                    await ctx.persist('req-001', { result: 'value' } as never)
                },
                {
                    config: testConfig,
                    sourceId: 'source-1',
                    sdk: {
                        sources: { getSourceSchemasV1: vi.fn() } as any,
                        accounts: accountsApi as any,
                    },
                }
            )

            const invocation = wrapped(
                { commandType: 'custom:test', config: testConfig } as any,
                { requestId: 'req-001' },
                res as any
            )
            const assertion = invocation.then(() => {
                expect(res.send).toHaveBeenCalledWith(
                    expect.objectContaining({
                        status: 'failed',
                        error: expect.stringMatching(/account not found after retries/),
                    })
                )
                expect(
                    upsertAttributes.some(
                        (attributes) =>
                            attributes.status === 'failed' &&
                            String(attributes.details).match(/account not found after retries/)
                    )
                ).toBe(true)
            })
            await vi.runAllTimersAsync()
            await assertion
        } finally {
            vi.useRealTimers()
        }
    })

    it('persists failed account with details when handler throws in test mode', async () => {
        process.env.SPCX_TEST_MODE = '1'
        const res = mockResponse()
        const wrapped = customOperation<TestOperation>(
            async () => {
                throw new Error('operation failed')
            },
            { sourceId: 'source-1' }
        )

        beginPayloadOutputCapture()
        await wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-fail-details' }, res as any)
        const inhibited = endPayloadOutputCapture()

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({ status: 'failed', error: expect.stringMatching(/operation failed/) })
        )
        expect(inhibited).toEqual([
            expect.objectContaining({
                identity: 'req-fail-details',
                status: 'failed',
                attributes: expect.objectContaining({
                    details: expect.stringMatching(/operation failed/),
                }),
            }),
        ])
    })

    it('persists failed account with details when handler sends failed response', async () => {
        process.env.SPCX_TEST_MODE = '1'
        const res = mockResponse()
        const wrapped = customOperation<TestOperation>(async (ctx) => {
            ctx.res.send({ status: 'failed', error: 'form create failed' })
        })

        beginPayloadOutputCapture()
        await wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-send-failed' }, res as any)
        const inhibited = endPayloadOutputCapture()

        expect(inhibited).toEqual([
            expect.objectContaining({
                identity: 'req-send-failed',
                status: 'failed',
                attributes: expect.objectContaining({ details: 'form create failed' }),
            }),
        ])
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

    it('sends status failed for partial config with missing connection fields', async () => {
        const res = { send: vi.fn() }
        const wrapped = customOperation<TestOperation>(async () => {}, {
            config: { testMode: true },
        })

        await wrapped({ commandType: 'custom:test' } as any, { requestId: 'req-001' }, res as any)

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringMatching(/Missing required config fields/),
            })
        )
    })

    it('sends status failed when ISC status check fails with token present', async () => {
        const res = { send: vi.fn() }
        const sourcesApi = {
            listSourcesV1: vi.fn().mockRejectedValue(new Error('Unauthorized')),
            createSourceV1: vi.fn(),
        }
        const wrapped = customOperation<TestOperation>(async () => {}, {
            config: { ...testConfig, testMode: true },
            sdk: {
                sources: sourcesApi as any,
                accounts: {
                    createAccountV1: vi.fn(),
                    putAccountV1: vi.fn(),
                    deleteAccountAsyncV1: vi.fn(),
                    listAccountsV1: vi.fn(),
                } as any,
            },
        })

        await wrapped(
            { commandType: 'custom:test', config: { ...testConfig, testMode: true } } as any,
            { requestId: 'req-001' },
            res as any
        )

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringMatching(/Unauthorized/),
            })
        )
    })

    it('sends status failed for handler plain Error instead of throwing', async () => {
        const res = { send: vi.fn() }
        const wrapped = customOperation<TestOperation>(
            async () => {
                throw new Error('operation failed')
            },
            {
                config: testConfig,
                sourceId: 'source-1',
                sdk: {
                    sources: { listSourcesV1: vi.fn(), createSourceV1: vi.fn() } as any,
                    accounts: {
                        createAccountV1: vi.fn(),
                        putAccountV1: vi.fn(),
                        deleteAccountAsyncV1: vi.fn(),
                        listAccountsV1: vi.fn(),
                    } as any,
                },
            }
        )

        await wrapped({ commandType: 'custom:test', config: testConfig } as any, { requestId: 'req-001' }, res as any)

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringMatching(/operation failed/),
            })
        )
    })

    it('skips all ISC API calls when no config is provided', async () => {
        process.env.SPCX_TEST_MODE = '1'
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
        const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const res = { send: vi.fn() }
        const sourcesApi = { listSourcesV1: vi.fn(), createSourceV1: vi.fn() }
        const accountsApi = { createAccountV1: vi.fn(), putAccountV1: vi.fn(), listAccountsV1: vi.fn() }
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

    it('offline SDK accounts stub throws ConnectorError', async () => {
        const ctx = createRequestContext(
            { apiUrl: '', token: '', sourceName: 'test-mode-local', requestId: 'offline-001' },
            { send: vi.fn() },
            { testMode: true, sourceId: 'test-mode-local' }
        )

        expect(() =>
            ctx.sdk.accounts.createAccountV1({ accountAttributesCreate: { attributes: {} } } as any)
        ).toThrow(ConnectorError)
    })

    it('checks ISC status and resolves source read-only when token is provided', async () => {
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
        const res = { send: vi.fn() }
        const sourcesApi = {
            listSourcesV1: vi
                .fn()
                .mockResolvedValueOnce({ data: [] })
                .mockResolvedValueOnce({ data: [{ id: 'source-readonly', name: 'SaaS Custom Operations', type: 'DelimitedFile' }] }),
            createSourceV1: vi.fn(),
        }
        const accountsApi = { createAccountV1: vi.fn(), putAccountV1: vi.fn(), listAccountsV1: vi.fn() }
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
            sdk: { sources: sourcesApi as any, accounts: { createAccountV1: vi.fn(), putAccountV1: vi.fn(), listAccountsV1: vi.fn() } as any },
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
            sdk: { sources: sourcesApi as any, accounts: { createAccountV1: vi.fn(), putAccountV1: vi.fn(), listAccountsV1: vi.fn() } as any },
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
