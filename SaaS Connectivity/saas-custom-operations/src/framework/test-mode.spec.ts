import { describe, expect, it, beforeEach, afterEach } from 'vitest'
import { hasAccessToken, isTestMode } from './test-mode'
import { normalizeAccessToken } from './with-custom-operation'

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

describe('hasAccessToken', () => {
    it('returns false for missing or empty token', () => {
        expect(hasAccessToken({})).toBe(false)
        expect(hasAccessToken({ token: '' })).toBe(false)
        expect(hasAccessToken({ token: '   ' })).toBe(false)
    })

    it('returns true for non-empty token after normalization', () => {
        expect(hasAccessToken({ token: 'pat-token' })).toBe(true)
        expect(hasAccessToken({ token: ' Bearer eyJ.test.sig ' })).toBe(true)
        expect(normalizeAccessToken(' Bearer eyJ.test.sig ')).toBe('eyJ.test.sig')
    })
})
