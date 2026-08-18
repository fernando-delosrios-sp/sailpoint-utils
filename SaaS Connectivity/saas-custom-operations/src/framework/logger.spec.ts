import { describe, expect, it, vi } from 'vitest'
import { createFrameworkLogger, resolveLogUrlFromConfig, sanitizeForLog } from './logger'

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

describe('createFrameworkLogger', () => {
    it('always writes to console with requestId prefix', () => {
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

    it('applies the same detail redaction to console and logUrl', () => {
        const fetchImpl = vi.fn().mockResolvedValue({ ok: true })
        const consoleImpl = {
            log: vi.fn(),
            warn: vi.fn(),
            error: vi.fn(),
        }
        const detail = { token: 'secret-token-value', status: 'ok' }
        const logger = createFrameworkLogger({
            requestId: 'req-001',
            logUrl: 'https://logs.example.com/ingest',
            fetchImpl,
            consoleImpl,
        })

        logger.info('step complete', detail)

        const consoleLine = String(consoleImpl.log.mock.calls[0]?.[0])
        const body = JSON.parse(String(fetchImpl.mock.calls[0]?.[1]?.body))

        expect(consoleLine).toContain('[REDACTED]')
        expect(consoleLine).not.toContain('secret-token-value')
        expect(body.detail).toEqual({ token: '[REDACTED]', status: 'ok' })
    })
})
