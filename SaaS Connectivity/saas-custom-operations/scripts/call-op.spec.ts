import { describe, expect, it, vi, afterEach } from 'vitest'
import { readFileSync } from 'fs'
import { join } from 'path'
import { loadPayload, normalizePayloadConfig, runPayload, runPayloadFromPath } from './call-op'
import { OPERATION_HANDLERS } from '../src/operations/auto-registry'
import connectorSpec from '../connector-spec.json'
import { customOperation } from '../src/framework/with-custom-operation'
import { writeFileSync, unlinkSync } from 'fs'
import { tmpdir } from 'os'

describe('call-op', () => {
    const originalEnv = process.env.SPCX_TEST_MODE

    afterEach(() => {
        if (originalEnv === undefined) {
            delete process.env.SPCX_TEST_MODE
        } else {
            process.env.SPCX_TEST_MODE = originalEnv
        }
    })

    it('rejects payload missing type', () => {
        const path = join(tmpdir(), `payload-${Date.now()}.json`)
        writeFileSync(path, JSON.stringify({ input: { requestId: 'x' } }))
        try {
            expect(() => loadPayload(path)).toThrow(/type/)
        } finally {
            unlinkSync(path)
        }
    })

    it('runs valid offline payload without config and returns res.send payload', async () => {
        delete process.env.SPCX_TEST_MODE
        const { response } = await runPayload({
            type: 'custom:example',
            input: { requestId: 'payload-run-001', message: 'hello' },
        })

        expect(response).toEqual({ status: 'success' })
    })

    it('passes payload config to handler context when config is present', async () => {
        let receivedContext: { commandType?: string; config?: Record<string, unknown> } | undefined
        const handler = vi.fn(async (context: unknown, _input: unknown, res: { send: (p: unknown) => void }) => {
            receivedContext = context as typeof receivedContext
            res.send({ ok: true })
        })

        const payloadConfig = {
            testMode: true,
            apiUrl: 'https://example.com',
            token: 't',
            sourceName: 'S',
        }

        await runPayload(
            {
                type: 'custom:probe',
                config: payloadConfig,
                input: { requestId: 'cfg-001' },
            },
            { 'custom:probe': handler as never }
        )

        expect(handler).toHaveBeenCalledOnce()
        expect(receivedContext?.commandType).toBe('custom:probe')
        expect(receivedContext?.config).toEqual(payloadConfig)
    })

    it('omits context.config when payload has no config key', async () => {
        let receivedContext: { config?: Record<string, unknown> } | undefined
        const handler = vi.fn(async (context: unknown, _input: unknown, res: { send: (p: unknown) => void }) => {
            receivedContext = context as typeof receivedContext
            res.send({ ok: true })
        })

        await runPayload(
            {
                type: 'custom:probe',
                input: { requestId: 'offline-001' },
            },
            { 'custom:probe': handler as never }
        )

        expect(receivedContext?.config).toBeUndefined()
    })

    it('preserves config when present in payload file', () => {
        const path = join(tmpdir(), `payload-with-config-${Date.now()}.json`)
        writeFileSync(
            path,
            JSON.stringify({
                type: 'custom:example',
                config: { testMode: true, apiUrl: 'https://example.com', token: 't', sourceName: 'S' },
                input: { requestId: 'x' },
            })
        )
        try {
            const payload = loadPayload(path)
            expect(payload.config?.testMode).toBe(true)
            expect(payload.config?.apiUrl).toBe('https://example.com')
        } finally {
            unlinkSync(path)
        }
    })

    it('normalizes config.url to apiUrl when loading payload', () => {
        expect(normalizePayloadConfig({ url: 'https://tenant.example.com', token: 't', sourceName: 'S' })?.apiUrl).toBe(
            'https://tenant.example.com'
        )
    })

    it('returns exit code 1 with helpful message for missing apiUrl', async () => {
        const path = join(tmpdir(), `payload-bad-config-${Date.now()}.json`)
        writeFileSync(
            path,
            JSON.stringify({
                type: 'custom:example',
                config: { token: 't', sourceName: 'S' },
                input: { requestId: 'x' },
            })
        )
        const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
        try {
            expect(await runPayloadFromPath(path)).toBe(1)
            expect(errorSpy).toHaveBeenCalledWith(expect.stringMatching(/missing: apiUrl/))
            expect(errorSpy).toHaveBeenCalledWith(expect.stringMatching(/sod-remediation-offline/))
        } finally {
            unlinkSync(path)
            errorSpy.mockRestore()
        }
    })

    it('returns exit code 1 for payload missing type', async () => {
        const path = join(tmpdir(), `payload-missing-type-${Date.now()}.json`)
        writeFileSync(path, JSON.stringify({ input: { requestId: 'x' } }))
        const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
        try {
            expect(await runPayloadFromPath(path)).toBe(1)
            expect(errorSpy).toHaveBeenCalledWith(expect.stringMatching(/type/))
        } finally {
            unlinkSync(path)
            errorSpy.mockRestore()
        }
    })

    it('returns exit code 1 when handler response has failed status', async () => {
        delete process.env.SPCX_TEST_MODE
        const path = join(tmpdir(), `payload-failed-status-${Date.now()}.json`)
        writeFileSync(
            path,
            JSON.stringify({
                type: 'custom:governance-group-emails',
                input: { requestId: 'exit-fail-001' },
            })
        )
        const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
        try {
            expect(await runPayloadFromPath(path)).toBe(1)
            expect(errorSpy).toHaveBeenCalledWith(expect.stringMatching(/Missing required input field: groupName/))
        } finally {
            unlinkSync(path)
            errorSpy.mockRestore()
        }
    })

    it('returns failed inhibited persist with details for customOperation failed response', async () => {
        delete process.env.SPCX_TEST_MODE
        const failedOperation = customOperation(async (ctx) => {
            ctx.res.send({ status: 'failed', error: 'operation failed' })
        })

        const { response, inhibitedPersists } = await runPayload(
            {
                type: 'custom:probe-failed',
                input: { requestId: 'offline-fail-001' },
            },
            { 'custom:probe-failed': failedOperation }
        )

        expect(response).toEqual({ status: 'failed', error: 'operation failed' })
        expect(inhibitedPersists).toEqual([
            expect.objectContaining({
                identity: 'offline-fail-001',
                status: 'failed',
                attributes: expect.objectContaining({
                    details: 'operation failed',
                    operationName: 'custom:probe-failed',
                }),
            }),
        ])
    })

    it('documents npm call:op script in package.json', () => {
        const pkg = JSON.parse(readFileSync(join(process.cwd(), 'package.json'), 'utf-8'))
        expect(pkg.scripts['call:op']).toContain('call-op')
    })

    it('documents call:op resolving handlers from codegen without manual call-op registration', () => {
        const readme = readFileSync(join(process.cwd(), 'README.md'), 'utf-8')
        expect(readme).toMatch(/npm run call:op/)
        expect(readme).toMatch(/OPERATION_HANDLERS/)
        expect(readme).toMatch(/auto-registry/)
        expect(readme).not.toMatch(/register its handler in `OPERATION_HANDLERS`/i)
    })

    it('resolves all connector commands from codegen OPERATION_HANDLERS', () => {
        for (const command of connectorSpec.commands) {
            expect(OPERATION_HANDLERS[command]).toBeTypeOf('function')
        }
    })

    it('invokes every connector command via runPayload without manual handler map', async () => {
        delete process.env.SPCX_TEST_MODE
        for (const command of connectorSpec.commands) {
            const result = await runPayload({ type: command, input: { requestId: `smoke-${command}` } })
            expect(result).toHaveProperty('response')
        }
    })
})
