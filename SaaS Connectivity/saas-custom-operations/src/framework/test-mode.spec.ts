import { describe, expect, it, afterEach } from 'vitest'
import { isTestMode, resolveInvocationConfig } from './test-mode'

describe('isTestMode', () => {
    const originalEnv = process.env.SPCX_TEST_MODE

    afterEach(() => {
        if (originalEnv === undefined) {
            delete process.env.SPCX_TEST_MODE
        } else {
            process.env.SPCX_TEST_MODE = originalEnv
        }
    })

    it('is disabled by default', () => {
        delete process.env.SPCX_TEST_MODE
        expect(isTestMode({})).toBe(false)
    })

    it('is enabled via config.testMode true', () => {
        expect(isTestMode({ testMode: true })).toBe(true)
    })

    it('is enabled via SPCX_TEST_MODE env fallback', () => {
        process.env.SPCX_TEST_MODE = '1'
        expect(isTestMode({})).toBe(true)
    })

    it('is disabled when config.testMode is explicitly false even if env is set', () => {
        process.env.SPCX_TEST_MODE = '1'
        expect(isTestMode({ testMode: false })).toBe(false)
    })
})

describe('resolveInvocationConfig', () => {
    it('prefers deps.config when provided', async () => {
        const result = await resolveInvocationConfig(
            { config: { testMode: true, token: 'x' } },
            {},
            async () => ({ apiUrl: 'ignored' })
        )
        expect(result.configProvided).toBe(true)
        expect(result.config.token).toBe('x')
    })

    it('uses context.config when deps.config is absent', async () => {
        const result = await resolveInvocationConfig({}, { config: { testMode: true } }, async () => ({}))
        expect(result.configProvided).toBe(true)
    })

    it('treats empty readConfig result as config not provided', async () => {
        const result = await resolveInvocationConfig({}, {}, async () => ({}))
        expect(result.configProvided).toBe(false)
    })

    it('treats non-empty readConfig result as config provided', async () => {
        const result = await resolveInvocationConfig(
            {},
            {},
            async () => ({ apiUrl: 'https://example.com', token: 't', sourceName: 'S' })
        )
        expect(result.configProvided).toBe(true)
    })

    it('returns config not provided when readConfig fails', async () => {
        const result = await resolveInvocationConfig(
            {},
            {},
            async () => {
                throw new Error('no config file')
            }
        )
        expect(result.configProvided).toBe(false)
        expect(result.config).toEqual({})
    })
})
