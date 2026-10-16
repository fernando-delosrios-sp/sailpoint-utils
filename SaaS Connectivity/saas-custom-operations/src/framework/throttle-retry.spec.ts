import { describe, expect, it, vi } from 'vitest'
import {
    installThrottleRetry,
    resolveThrottleDelay,
    resolveThrottleDelayMs,
    RetryingAxiosInstance,
} from './throttle-retry'

const NOW = new Date('2026-09-22T16:00:00.000Z')

/** Captures the rejection handler the installer registers so a test can drive it directly. */
function mockAxios(): {
    instance: RetryingAxiosInstance
    request: ReturnType<typeof vi.fn>
    reject: (error: unknown) => Promise<unknown>
    requestInterceptor: (config: Record<string, unknown>) => Promise<Record<string, unknown>>
} {
    const request = vi.fn()
    let onRejected: (error: unknown) => Promise<unknown> = async (error) => {
        throw error
    }
    let onRequest: (config: Record<string, unknown>) => Promise<Record<string, unknown>> = async (config) => config

    const instance: RetryingAxiosInstance = {
        interceptors: {
            request: {
                use: (handler) => {
                    onRequest = handler as (config: Record<string, unknown>) => Promise<Record<string, unknown>>
                },
            },
            response: {
                use: (_onFulfilled, handler) => {
                    onRejected = handler
                },
            },
        },
        request,
    }

    return {
        instance,
        request,
        reject: (error) => onRejected(error),
        requestInterceptor: (config) => onRequest(config),
    }
}

function throttled(config: Record<string, unknown> = {}, headers: Record<string, unknown> = {}) {
    return { config, response: { status: 429, headers } }
}

describe('resolveThrottleDelayMs', () => {
    it('honors Retry-After in seconds without shortening it', () => {
        expect(resolveThrottleDelayMs({ headers: { 'retry-after': '3' }, retryNumber: 1, now: NOW })).toBe(3_000)
    })

    it('honors Retry-After as an HTTP date', () => {
        const headers = { 'Retry-After': 'Tue, 22 Sep 2026 16:00:05 GMT' }

        expect(resolveThrottleDelayMs({ headers, retryNumber: 1, now: NOW })).toBe(5_000)
    })

    it('backs off exponentially with jitter when the response carries no Retry-After', () => {
        const delays = [1, 2, 3].map((retryNumber) =>
            resolveThrottleDelayMs({
                retryNumber,
                baseDelayMs: 500,
                jitterRatio: 0,
                random: () => 0.5,
                now: NOW,
            })
        )

        expect(delays).toEqual([500, 1_000, 2_000])
    })

    it('caps exponential backoff but not a server Retry-After', () => {
        const fromBackoff = resolveThrottleDelayMs({
            retryNumber: 9,
            baseDelayMs: 1_000,
            maxBackoffMs: 20_000,
            jitterRatio: 0,
            now: NOW,
        })
        const fromHeader = resolveThrottleDelayMs({
            headers: { 'retry-after': '45' },
            retryNumber: 1,
            maxBackoffMs: 20_000,
            now: NOW,
        })

        expect(fromBackoff).toBe(20_000)
        expect(fromHeader).toBe(45_000)
    })

    it('rejects when Retry-After exceeds the allowed wait', () => {
        expect(
            resolveThrottleDelay({
                headers: { 'retry-after': '600' },
                retryNumber: 1,
                maxRetryAfterMs: 20_000,
                now: NOW,
            })
        ).toEqual({ delayMs: 600_000, reject: true })
    })

    it('treats an elapsed Retry-After date as no delay', () => {
        const headers = { 'retry-after': 'Tue, 22 Sep 2026 15:59:50 GMT' }

        expect(resolveThrottleDelayMs({ headers, retryNumber: 1, now: NOW })).toBe(0)
    })

    it('applies jitter within the configured ratio', () => {
        const delay = resolveThrottleDelayMs({
            retryNumber: 1,
            baseDelayMs: 1_000,
            jitterRatio: 0.2,
            random: () => 1,
            now: NOW,
        })
        // Midpoint 1000, spread 200 → max 1100
        expect(delay).toBe(1_100)
    })
})

describe('installThrottleRetry', () => {
    it('waits and re-issues the same request on 429', async () => {
        const { instance, request, reject } = mockAxios()
        const sleep = vi.fn().mockResolvedValue(undefined)
        request.mockResolvedValue({ status: 200 })
        installThrottleRetry(instance, { sleep, baseDelayMs: 1_000, jitterRatio: 0, random: () => 0.5 })

        const config = { url: '/v2026/roles' }
        const result = await reject(throttled(config))

        expect(sleep).toHaveBeenCalledWith(1_000)
        expect(request).toHaveBeenCalledWith(config)
        expect(result).toEqual({ status: 200 })
    })

    it('lengthens the wait across successive retries of one request', async () => {
        const { instance, request, reject } = mockAxios()
        const sleep = vi.fn().mockResolvedValue(undefined)
        request.mockResolvedValue({ status: 200 })
        installThrottleRetry(instance, { sleep, baseDelayMs: 1_000, jitterRatio: 0, random: () => 0.5 })

        const config = { url: '/v2026/roles' }
        await reject(throttled(config))
        await reject(throttled(config))

        expect(sleep.mock.calls).toEqual([[1_000], [2_000]])
    })

    it('gives up once the retry budget is spent', async () => {
        const { instance, request, reject } = mockAxios()
        const sleep = vi.fn().mockResolvedValue(undefined)
        installThrottleRetry(instance, { sleep, maxRetries: 2, jitterRatio: 0 })

        const config = { url: '/v2026/roles' }
        await reject(throttled(config))
        await reject(throttled(config))
        await expect(reject(throttled(config))).rejects.toMatchObject({ response: { status: 429 } })

        expect(request).toHaveBeenCalledTimes(2)
    })

    it('surfaces a 429 when Retry-After exceeds the allowed wait', async () => {
        const { instance, request, reject } = mockAxios()
        const sleep = vi.fn().mockResolvedValue(undefined)
        installThrottleRetry(instance, { sleep, maxRetryAfterMs: 5_000 })

        await expect(reject(throttled({ url: '/v2026/roles' }, { 'retry-after': '30' }))).rejects.toMatchObject({
            response: { status: 429 },
        })
        expect(sleep).not.toHaveBeenCalled()
        expect(request).not.toHaveBeenCalled()
    })

    it('pauses later requests during the shared cooldown', async () => {
        const start = Date.parse('2026-09-22T16:00:00.000Z')
        let clock = start
        const { instance, request, reject, requestInterceptor } = mockAxios()
        // Do not advance the clock during the 429 retry wait — the cooldown is still in the future.
        const sleep = vi.fn().mockResolvedValue(undefined)
        request.mockResolvedValue({ status: 200 })
        installThrottleRetry(instance, {
            sleep,
            baseDelayMs: 1_000,
            jitterRatio: 0,
            random: () => 0.5,
            now: () => clock,
        })

        await reject(throttled({ url: '/v2026/roles' }))
        sleep.mockClear()
        // Still at the original instant; cooldownUntil is start + 1000.
        clock = start

        await requestInterceptor({ url: '/v2026/entitlements' })
        expect(sleep).toHaveBeenCalledWith(1_000)
    })

    it('rethrows anything that is not a throttle response', async () => {
        const { instance, request, reject } = mockAxios()
        installThrottleRetry(instance, { sleep: vi.fn() })

        await expect(reject({ config: {}, response: { status: 500 } })).rejects.toMatchObject({
            response: { status: 500 },
        })
        await expect(reject(new Error('socket hang up'))).rejects.toThrow('socket hang up')
        expect(request).not.toHaveBeenCalled()
    })

    it('reports each retry to the caller', async () => {
        const { instance, request, reject } = mockAxios()
        const onRetry = vi.fn()
        request.mockResolvedValue({ status: 200 })
        installThrottleRetry(instance, {
            sleep: vi.fn().mockResolvedValue(undefined),
            baseDelayMs: 1_000,
            jitterRatio: 0,
            random: () => 0.5,
            onRetry,
        })

        await reject(throttled({ url: '/v2026/roles' }))

        expect(onRetry).toHaveBeenCalledWith({ attempt: 1, delayMs: 1_000, url: '/v2026/roles' })
    })
})
