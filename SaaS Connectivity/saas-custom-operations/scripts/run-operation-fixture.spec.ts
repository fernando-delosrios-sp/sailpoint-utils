import { describe, expect, it, vi, afterEach } from 'vitest'
import { readFileSync } from 'fs'
import { join } from 'path'
import { loadFixture, normalizeFixtureConfig, runFixture, runFixtureFromPath } from './run-operation-fixture'
import { writeFileSync, unlinkSync } from 'fs'
import { tmpdir } from 'os'

describe('run-operation-fixture', () => {
    const originalEnv = process.env.SPCX_TEST_MODE

    afterEach(() => {
        if (originalEnv === undefined) {
            delete process.env.SPCX_TEST_MODE
        } else {
            process.env.SPCX_TEST_MODE = originalEnv
        }
    })

    it('rejects fixture missing command', () => {
        const path = join(tmpdir(), `fixture-${Date.now()}.json`)
        writeFileSync(path, JSON.stringify({ input: { requestId: 'x' } }))
        try {
            expect(() => loadFixture(path)).toThrow(/command/)
        } finally {
            unlinkSync(path)
        }
    })

    it('runs valid offline fixture without config and returns res.send payload', async () => {
        delete process.env.SPCX_TEST_MODE
        const { response } = await runFixture({
            command: 'custom:example',
            input: { requestId: 'fixture-run-001', message: 'hello' },
        })

        expect(response).toEqual({ status: 'success' })
    })

    it('passes fixture config to handler context when config is present', async () => {
        let receivedContext: { commandType?: string; config?: Record<string, unknown> } | undefined
        const handler = vi.fn(async (context: unknown, _input: unknown, res: { send: (p: unknown) => void }) => {
            receivedContext = context as typeof receivedContext
            res.send({ ok: true })
        })

        const fixtureConfig = {
            testMode: true,
            apiUrl: 'https://example.com',
            token: 't',
            sourceName: 'S',
        }

        await runFixture(
            {
                command: 'custom:probe',
                config: fixtureConfig,
                input: { requestId: 'cfg-001' },
            },
            { 'custom:probe': handler as never }
        )

        expect(handler).toHaveBeenCalledOnce()
        expect(receivedContext?.commandType).toBe('custom:probe')
        expect(receivedContext?.config).toEqual(fixtureConfig)
    })

    it('omits context.config when fixture has no config key', async () => {
        let receivedContext: { config?: Record<string, unknown> } | undefined
        const handler = vi.fn(async (context: unknown, _input: unknown, res: { send: (p: unknown) => void }) => {
            receivedContext = context as typeof receivedContext
            res.send({ ok: true })
        })

        await runFixture(
            {
                command: 'custom:probe',
                input: { requestId: 'offline-001' },
            },
            { 'custom:probe': handler as never }
        )

        expect(receivedContext?.config).toBeUndefined()
    })

    it('preserves config when present in fixture file', () => {
        const path = join(tmpdir(), `fixture-with-config-${Date.now()}.json`)
        writeFileSync(
            path,
            JSON.stringify({
                command: 'custom:example',
                config: { testMode: true, apiUrl: 'https://example.com', token: 't', sourceName: 'S' },
                input: { requestId: 'x' },
            })
        )
        try {
            const fixture = loadFixture(path)
            expect(fixture.config?.testMode).toBe(true)
            expect(fixture.config?.apiUrl).toBe('https://example.com')
        } finally {
            unlinkSync(path)
        }
    })

    it('normalizes config.url to apiUrl when loading fixture', () => {
        expect(normalizeFixtureConfig({ url: 'https://tenant.example.com', token: 't', sourceName: 'S' })?.apiUrl).toBe(
            'https://tenant.example.com'
        )
    })

    it('returns exit code 1 with helpful message for missing apiUrl', async () => {
        const path = join(tmpdir(), `fixture-bad-config-${Date.now()}.json`)
        writeFileSync(
            path,
            JSON.stringify({
                command: 'custom:example',
                config: { token: 't', sourceName: 'S' },
                input: { requestId: 'x' },
            })
        )
        const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
        try {
            expect(await runFixtureFromPath(path)).toBe(1)
            expect(errorSpy).toHaveBeenCalledWith(expect.stringMatching(/missing: apiUrl/))
            expect(errorSpy).toHaveBeenCalledWith(expect.stringMatching(/sod-remediation-offline/))
        } finally {
            unlinkSync(path)
            errorSpy.mockRestore()
        }
    })

    it('returns exit code 1 for fixture missing command', async () => {
        const path = join(tmpdir(), `fixture-missing-cmd-${Date.now()}.json`)
        writeFileSync(path, JSON.stringify({ input: { requestId: 'x' } }))
        const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
        try {
            expect(await runFixtureFromPath(path)).toBe(1)
            expect(errorSpy).toHaveBeenCalledWith(expect.stringMatching(/command/))
        } finally {
            unlinkSync(path)
            errorSpy.mockRestore()
        }
    })

    it('documents npm test:operation script in package.json', () => {
        const pkg = JSON.parse(readFileSync(join(process.cwd(), 'package.json'), 'utf-8'))
        expect(pkg.scripts['test:operation']).toContain('run-operation-fixture')
    })
})

