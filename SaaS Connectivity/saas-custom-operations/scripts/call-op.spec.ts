import { describe, expect, it, vi, afterEach } from 'vitest'
import { readFileSync } from 'fs'
import { join } from 'path'
import { loadPayload, normalizePayloadConfig, runPayload, runPayloadFromPath } from './call-op'
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

    it('documents npm call:op script in package.json', () => {
        const pkg = JSON.parse(readFileSync(join(process.cwd(), 'package.json'), 'utf-8'))
        expect(pkg.scripts['call:op']).toContain('call-op')
    })
})
