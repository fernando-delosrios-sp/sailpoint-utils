import { describe, expect, it, vi } from 'vitest'
import { installThrottleRetry, resolveThrottleDelayMs, RetryingAxiosInstance } from './throttle-retry'

const NOW = new Date('2026-09-22T16:00:00.000Z')

/** Captures the rejection handler the installer registers so a test can drive it directly. */
function mockAxios(): {
    instance: RetryingAxiosInstance
    request: ReturnType<typeof vi.fn>
    reject: (error: unknown) => Promise<unknown>
} {
    const request = vi.fn()
    let onRejected: (error: unknown) => Promise<unknown> = async (error) => {
        throw error
    }

    const instance: RetryingAxiosInstance = {
        interceptors: {
            response: {
                use: (_onFulfilled, handler) => {
                    onRejected = handler
                },
            },
        },
        request,
    }

    return { instance, request, reject: (error) => onRejected(error) }
}

function throttled(config: Record<string, unknown> = {}, headers: Record<string, unknown> = {}) {
    return { config, response: { status: 429, headers } }
}

describe('resolveThrottleDelayMs', () => {
    it('honors Retry-After in seconds', () => {
        expect(resolveThrottleDelayMs({ headers: { 'retry-after': '3' }, retryNumber: 1, now: NOW })).toBe(3_000)
    })

    it('honors Retry-After as an HTTP date', () => {
        const headers = { 'Retry-After': 'Tue, 22 Sep 2026 16:00:05 GMT' }

        expect(resolveThrottleDelayMs({ headers, retryNumber: 1, now: NOW })).toBe(5_000)
    })

    it('backs off exponentially when the response carries no Retry-After', () => {
        const delays = [1, 2, 3].map((retryNumber) =>
            resolveThrottleDelayMs({ retryNumber, baseDelayMs: 500, now: NOW })
        )

        expect(delays).toEqual([500, 1_000, 2_000])
    })

    it('caps any delay at the maximum', () => {
        const fromHeader = resolveThrottleDelayMs({
            headers: { 'retry-after': '600' },
            retryNumber: 1,
            maxDelayMs: 20_000,
            now: NOW,
        })
        const fromBackoff = resolveThrottleDelayMs({ retryNumber: 9, baseDelayMs: 1_000, maxDelayMs: 20_000, now: NOW })

        expect(fromHeader).toBe(20_000)
        expect(fromBackoff).toBe(20_000)
    })

    it('treats an elapsed Retry-After date as no delay', () => {
        const headers = { 'retry-after': 'Tue, 22 Sep 2026 15:59:50 GMT' }

        expect(resolveThrottleDelayMs({ headers, retryNumber: 1, now: NOW })).toBe(0)
    })
})

describe('installThrottleRetry', () => {
    it('waits and re-issues the same request on 429', async () => {
        const { instance, request, reject } = mockAxios()
        const sleep = vi.fn().mockResolvedValue(undefined)
        request.mockResolvedValue({ status: 200 })
        installThrottleRetry(instance, { sleep, baseDelayMs: 1_000 })

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
        installThrottleRetry(instance, { sleep, baseDelayMs: 1_000 })

        const config = { url: '/v2026/roles' }
        await reject(throttled(config))
        await reject(throttled(config))

        expect(sleep.mock.calls).toEqual([[1_000], [2_000]])
    })

    it('gives up once the retry budget is spent', async () => {
        const { instance, request, reject } = mockAxios()
        const sleep = vi.fn().mockResolvedValue(undefined)
        installThrottleRetry(instance, { sleep, maxRetries: 2 })

        const config = { url: '/v2026/roles' }
        await reject(throttled(config))
        await reject(throttled(config))
        await expect(reject(throttled(config))).rejects.toMatchObject({ response: { status: 429 } })

        expect(request).toHaveBeenCalledTimes(2)
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
        installThrottleRetry(instance, { sleep: vi.fn().mockResolvedValue(undefined), baseDelayMs: 1_000, onRetry })

        await reject(throttled({ url: '/v2026/roles' }))

        expect(onRetry).toHaveBeenCalledWith({ attempt: 1, delayMs: 1_000, url: '/v2026/roles' })
    })
})
