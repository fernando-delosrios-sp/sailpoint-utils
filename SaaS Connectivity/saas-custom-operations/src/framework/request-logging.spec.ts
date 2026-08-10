import { describe, expect, it, vi } from 'vitest'
import {
    formatIncomingRequest,
    redactConfigForLogging,
    resolveConfigForRequestLogging,
    withRequestLogging,
    wrapConnectorWithRequestLogging,
} from './request-logging'

describe('redactConfigForLogging', () => {
    it('redacts token while preserving other config fields', () => {
        expect(
            redactConfigForLogging({
                apiUrl: 'https://tenant.api.identitynow.com',
                token: 'secret-token',
                sourceName: 'SaaS Custom Operations',
            })
        ).toEqual({
            apiUrl: 'https://tenant.api.identitynow.com',
            token: '[REDACTED]',
            sourceName: 'SaaS Custom Operations',
        })
    })
})

describe('formatIncomingRequest', () => {
    it('formats command, config, and input like fixture output', () => {
        process.env.NO_COLOR = '1'
        const formatted = formatIncomingRequest({
            command: 'custom:example',
            config: {
                apiUrl: 'https://tenant.api.identitynow.com',
                token: 'secret-token',
                sourceName: 'SaaS Custom Operations',
                testMode: true,
            },
            input: {
                requestId: 'req-001',
                message: 'hello',
            },
        })

        expect(formatted).toContain('Incoming request')
        expect(formatted).toContain('command=custom:example')
        expect(formatted).toContain('requestId=req-001')
        expect(formatted).toContain('testMode=true')
        expect(formatted).toContain('"message": "hello"')
        expect(formatted).toContain('[REDACTED]')
        expect(formatted).not.toContain('secret-token')
        delete process.env.NO_COLOR
    })
})

describe('resolveConfigForRequestLogging', () => {
    it('prefers context.config over readConfig', async () => {
        const config = await resolveConfigForRequestLogging({
            config: { apiUrl: 'https://tenant.api.identitynow.com', token: 'secret', sourceName: 'Test' },
        } as never)

        expect(config).toEqual({
            apiUrl: 'https://tenant.api.identitynow.com',
            token: 'secret',
            sourceName: 'Test',
        })
    })
})

describe('withRequestLogging', () => {
    it('logs the invoke payload before delegating to the handler', async () => {
        process.env.NO_COLOR = '1'
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
        const handler = vi.fn(async () => {})
        const wrapped = withRequestLogging('custom:example', handler)

        await wrapped(
            {
                commandType: 'custom:example',
                config: {
                    apiUrl: 'https://tenant.api.identitynow.com',
                    token: 'secret-token',
                    sourceName: 'SaaS Custom Operations',
                },
            } as never,
            { requestId: 'req-001', message: 'hello' },
            { send: vi.fn() } as never
        )

        expect(handler).toHaveBeenCalledOnce()
        expect(logSpy.mock.calls[0]?.[0]).toContain('Incoming request')
        expect(logSpy.mock.calls[0]?.[0]).toContain('req-001')
        expect(logSpy.mock.calls[0]?.[0]).toContain('"sourceName": "SaaS Custom Operations"')
        expect(logSpy.mock.calls[0]?.[0]).not.toContain('secret-token')
        logSpy.mockRestore()
        delete process.env.NO_COLOR
    })
})

describe('wrapConnectorWithRequestLogging', () => {
    it('wraps handlers registered via connector.command', async () => {
        const handlers = new Map<string, ReturnType<typeof vi.fn>>()
        const connector = wrapConnectorWithRequestLogging({
            command: vi.fn((command: string, handler: (...args: unknown[]) => Promise<void>) => {
                handlers.set(
                    command,
                    vi.fn(async (...args: unknown[]) => handler(...args))
                )
                return connector
            }),
        } as never)

        const handler = vi.fn(async () => {})
        connector.command('custom:example', handler)

        expect(handlers.get('custom:example')).toBeDefined()
        expect(handler).not.toBe(handlers.get('custom:example'))
    })
})
