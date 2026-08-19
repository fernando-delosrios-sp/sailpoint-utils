import { describe, expect, it, vi } from 'vitest'
import {
    createFrameworkLogger,
    normalizeDetailForJson,
    resolveLogUrlFromConfig,
    sanitizeForLog,
} from './logger'

describe('resolveLogUrlFromConfig', () => {
    it('returns trimmed logUrl when present', () => {
        expect(resolveLogUrlFromConfig({ logUrl: '  https://logs.example.com/ingest  ' })).toBe(
            'https://logs.example.com/ingest'
        )
    })

    it('treats empty or whitespace logUrl as unset', () => {
        expect(resolveLogUrlFromConfig({ logUrl: '' })).toBeUndefined()
        expect(resolveLogUrlFromConfig({ logUrl: '   ' })).toBeUndefined()
        expect(resolveLogUrlFromConfig(undefined)).toBeUndefined()
    })
})

describe('sanitizeForLog', () => {
    it('redacts token fields in detail objects', () => {
        expect(sanitizeForLog({ token: 'secret-token-value' })).toEqual({ token: '[REDACTED]' })
    })
})

describe('normalizeDetailForJson', () => {
    it('omits undefined detail keys', () => {
        expect(normalizeDetailForJson({ present: 'ok', missing: undefined })).toEqual({ present: 'ok' })
    })

    it('omits function values from detail', () => {
        expect(normalizeDetailForJson({ ok: true, fn: () => {} })).toEqual({ ok: true })
    })

    it('omits symbol values from detail', () => {
        expect(normalizeDetailForJson({ ok: true, sym: Symbol('hidden') })).toEqual({ ok: true })
    })

    it('replaces circular references with [Circular]', () => {
        const payload: Record<string, unknown> = { label: 'loop' }
        payload.payload = payload

        expect(normalizeDetailForJson({ payload })).toEqual({
            payload: { label: 'loop', payload: '[Circular]' },
        })
    })

    it('serializes Error instances', () => {
        const error = new Error('boom')
        expect(normalizeDetailForJson({ error })).toEqual({
            error: { name: 'Error', message: 'boom', stack: error.stack },
        })
    })

    it('converts bigint values to strings', () => {
        expect(normalizeDetailForJson({ count: 3n })).toEqual({ count: '3' })
    })
})

describe('createFrameworkLogger', () => {
    it('always writes to console with requestId prefix headline', () => {
        const consoleImpl = {
            log: vi.fn(),
            warn: vi.fn(),
            error: vi.fn(),
        }
        const logger = createFrameworkLogger({
            requestId: 'req-001',
            consoleImpl,
        })

        logger.info('step complete')

        expect(consoleImpl.log).toHaveBeenCalledWith('[req-001] step complete')
    })

    it('renders named detail keys as labeled blocks with scalar inline', () => {
        const consoleImpl = {
            log: vi.fn(),
            warn: vi.fn(),
            error: vi.fn(),
        }
        const logger = createFrameworkLogger({
            requestId: 'wf-run-8842',
            consoleImpl,
        })

        logger.info('violation loaded', { violation: { id: 'v-1' }, count: 2 })

        const output = String(consoleImpl.log.mock.calls[0]?.[0])
        expect(output).toContain('[wf-run-8842] violation loaded')
        expect(output).toContain('  violation:')
        expect(output).toContain("id: 'v-1'")
        expect(output).toContain('  count: 2')
    })

    it('POSTs JSON when logUrl is configured', () => {
        const fetchImpl = vi.fn().mockResolvedValue({ ok: true })
        const now = () => new Date('2026-08-18T10:00:00.000Z')
        const logger = createFrameworkLogger({
            requestId: 'req-001',
            command: 'custom:example',
            logUrl: 'https://logs.example.com/ingest',
            fetchImpl,
            now,
            consoleImpl: { log: vi.fn(), warn: vi.fn(), error: vi.fn() },
        })

        logger.info('step complete', { token: 'secret' })

        expect(fetchImpl).toHaveBeenCalledWith(
            'https://logs.example.com/ingest',
            expect.objectContaining({
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
            })
        )

        const body = JSON.parse(String(fetchImpl.mock.calls[0]?.[1]?.body))
        expect(body).toMatchObject({
            timestamp: '2026-08-18T10:00:00.000Z',
            level: 'info',
            requestId: 'req-001',
            command: 'custom:example',
            message: 'step complete',
        })
        expect(body.detail.token).toBe('[REDACTED]')
    })

    it('does not fail the caller when POST rejects', async () => {
        const fetchImpl = vi.fn().mockRejectedValue(new Error('network down'))
        const logger = createFrameworkLogger({
            requestId: 'req-001',
            logUrl: 'https://logs.example.com/ingest',
            fetchImpl,
            consoleImpl: { log: vi.fn(), warn: vi.fn(), error: vi.fn() },
        })

        expect(() => logger.warn('still ok')).not.toThrow()
        await Promise.resolve()
        expect(fetchImpl).toHaveBeenCalled()
    })

    it('redacts token in console log detail', () => {
        const consoleImpl = {
            log: vi.fn(),
            warn: vi.fn(),
            error: vi.fn(),
        }
        const logger = createFrameworkLogger({
            requestId: 'req-001',
            consoleImpl,
        })

        logger.info('auth context', { token: 'secret-token-value' })

        const consoleLine = String(consoleImpl.log.mock.calls[0]?.[0])
        expect(consoleLine).toContain('[REDACTED]')
        expect(consoleLine).not.toContain('secret-token-value')
    })

    it('applies the same normalized detail to console and logUrl', () => {
        const fetchImpl = vi.fn().mockResolvedValue({ ok: true })
        const consoleImpl = {
            log: vi.fn(),
            warn: vi.fn(),
            error: vi.fn(),
        }
        const detail = { token: 'secret-token-value', status: 'ok', count: 3 }
        const logger = createFrameworkLogger({
            requestId: 'req-001',
            logUrl: 'https://logs.example.com/ingest',
            fetchImpl,
            consoleImpl,
        })

        logger.info('step complete', detail)

        const consoleLine = String(consoleImpl.log.mock.calls[0]?.[0])
        const body = JSON.parse(String(fetchImpl.mock.calls[0]?.[1]?.body))
        const expectedDetail = { token: '[REDACTED]', status: 'ok', count: 3 }

        expect(consoleLine).toContain('[REDACTED]')
        expect(consoleLine).not.toContain('secret-token-value')
        expect(consoleLine).toContain('  count: 3')
        expect(body.detail).toEqual(expectedDetail)
    })

    it('POSTs the same normalized detail as console for object detail maps', () => {
        const fetchImpl = vi.fn().mockResolvedValue({ ok: true })
        const consoleImpl = {
            log: vi.fn(),
            warn: vi.fn(),
            error: vi.fn(),
        }
        const detail = { violation: { id: 'v-1' } }
        const logger = createFrameworkLogger({
            requestId: 'req-001',
            logUrl: 'https://logs.example.com/ingest',
            fetchImpl,
            consoleImpl,
        })

        logger.info('violation loaded', detail)

        const body = JSON.parse(String(fetchImpl.mock.calls[0]?.[1]?.body))
        expect(body.detail).toEqual({ violation: { id: 'v-1' } })
    })
})
