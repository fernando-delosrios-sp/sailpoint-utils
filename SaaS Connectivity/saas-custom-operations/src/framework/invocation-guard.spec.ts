import { describe, expect, it, vi } from 'vitest'
import {
    invocationDedupeKey,
    isFailedCommandOutput,
    KEEP_ALIVE_INTERVAL_MS,
    startKeepAlive,
    stopKeepAlive,
} from './invocation-guard'

describe('invocationDedupeKey', () => {
    it('combines command type and trimmed requestId', () => {
        expect(invocationDedupeKey('custom:example', { requestId: '  req-1  ' })).toBe('custom:example:req-1')
    })

    it('returns undefined when requestId is missing', () => {
        expect(invocationDedupeKey('custom:example', {})).toBeUndefined()
    })

    it('uses formInstanceId for apply command dedupe key', () => {
        expect(
            invocationDedupeKey('custom:access-model-sod-remediation-apply', {
                requestId: 'req-1',
                formInstanceId: '  fi-1  ',
            })
        ).toBe('custom:access-model-sod-remediation-apply:fi-1')
    })

    it('returns undefined for apply command when formInstanceId is missing', () => {
        expect(invocationDedupeKey('custom:access-model-sod-remediation-apply', { requestId: 'req-1' })).toBeUndefined()
    })
})

describe('isFailedCommandOutput', () => {
    it('detects failed command payloads', () => {
        expect(isFailedCommandOutput({ status: 'failed', error: 'boom' })).toBe(true)
        expect(isFailedCommandOutput({ status: 'success' })).toBe(false)
    })
})

describe('keepAlive helpers', () => {
    it('pings immediately and on interval while active', () => {
        vi.useFakeTimers()
        try {
            const res = { keepAlive: vi.fn() }
            const timer = startKeepAlive(res as never)

            expect(res.keepAlive).toHaveBeenCalledTimes(1)

            vi.advanceTimersByTime(KEEP_ALIVE_INTERVAL_MS)
            expect(res.keepAlive).toHaveBeenCalledTimes(2)

            stopKeepAlive(timer)
            vi.advanceTimersByTime(KEEP_ALIVE_INTERVAL_MS)
            expect(res.keepAlive).toHaveBeenCalledTimes(2)
        } finally {
            vi.useRealTimers()
        }
    })
})
