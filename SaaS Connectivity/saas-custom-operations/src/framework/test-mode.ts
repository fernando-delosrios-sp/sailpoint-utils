import { normalizeAccessToken } from './with-custom-operation'

export const TEST_MODE_PLACEHOLDER_SOURCE_ID = 'test-mode-local'

/** True when config.testMode is true or SPCX_TEST_MODE=1 (unless explicitly false). */
export function isTestMode(config: Record<string, unknown>): boolean {
    if (config.testMode === false) {
        return false
    }
    if (config.testMode === true) {
        return true
    }
    return process.env.SPCX_TEST_MODE === '1'
}

/** True when config contains a non-empty access token after normalization. */
export function hasAccessToken(config: Record<string, unknown>): boolean {
    const raw = config.token
    if (raw == null || raw === '') {
        return false
    }
    return normalizeAccessToken(String(raw)).length > 0
}
