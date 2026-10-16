import { describe, expect, it, vi } from 'vitest'
import {
    createConcurrencyLimiter,
    installConcurrencyLimit,
    mapWithConcurrency,
    memoizeAsync,
    ConcurrentAxiosInstance,
} from './concurrency'

describe('mapWithConcurrency', () => {
    it('returns empty array for empty input', async () => {
        const run = vi.fn()
        await expect(mapWithConcurrency([], 5, run)).resolves.toEqual([])
        expect(run).not.toHaveBeenCalled()
    })

    it('preserves input order', async () => {
        const results = await mapWithConcurrency([3, 1, 2], 2, async (value) => value * 10)
        expect(results).toEqual([30, 10, 20])
    })

    it('never exceeds the concurrency limit', async () => {
        let inFlight = 0
        let maxInFlight = 0
        await mapWithConcurrency([1, 2, 3, 4, 5, 6], 2, async (value) => {
            inFlight++
            maxInFlight = Math.max(maxInFlight, inFlight)
            await new Promise((resolve) => setTimeout(resolve, 5))
            inFlight--
            return value
        })
        expect(maxInFlight).toBeLessThanOrEqual(2)
    })
})

describe('createConcurrencyLimiter', () => {
    it('never exceeds the permit count', async () => {
        const limiter = createConcurrencyLimiter(2)
        let inFlight = 0
        let maxInFlight = 0

        await Promise.all(
            [1, 2, 3, 4, 5].map((value) =>
                limiter.run(async () => {
                    inFlight++
                    maxInFlight = Math.max(maxInFlight, inFlight)
                    await new Promise((resolve) => setTimeout(resolve, 5))
                    inFlight--
                    return value
                })
            )
        )

        expect(maxInFlight).toBeLessThanOrEqual(2)
        expect(limiter.active).toBe(0)
        expect(limiter.waiting).toBe(0)
    })
})

describe('installConcurrencyLimit', () => {
    function mockAxios(): {
        instance: ConcurrentAxiosInstance
        handlers: {
            onRequest: (config: Record<string, unknown>) => Promise<Record<string, unknown>>
            onFulfilled: (response: { config: Record<string, unknown> }) => unknown
            onRejected: (error: unknown) => Promise<unknown>
        }
    } {
        const handlers = {
            onRequest: async (config: Record<string, unknown>) => config,
            onFulfilled: (response: { config: Record<string, unknown> }) => response as never,
            onRejected: async (error: unknown) => {
                throw error
            },
        }

        const instance: ConcurrentAxiosInstance = {
            interceptors: {
                request: {
                    use: (handler) => {
                        handlers.onRequest = handler as (
                            config: Record<string, unknown>
                        ) => Promise<Record<string, unknown>>
                    },
                },
                response: {
                    use: (fulfilled, rejected) => {
                        handlers.onFulfilled = fulfilled as (response: { config: Record<string, unknown> }) => unknown
                        handlers.onRejected = rejected
                    },
                },
            },
        }
        return { instance, handlers }
    }

    it('caps concurrent HTTP requests at the configured limit', async () => {
        const { instance, handlers } = mockAxios()
        const limiter = installConcurrencyLimit(instance, { limit: 2 })

        const configs = [{ url: '/a' }, { url: '/b' }, { url: '/c' }]
        const started: string[] = []
        const requestPromises = configs.map((config) =>
            handlers.onRequest(config).then((cfg) => {
                started.push(String(cfg.url))
                return cfg
            })
        )

        await new Promise((resolve) => setTimeout(resolve, 10))
        expect(started).toHaveLength(2)
        expect(limiter.active).toBe(2)

        handlers.onFulfilled({ config: configs[0] })
        await new Promise((resolve) => setTimeout(resolve, 10))
        expect(started).toHaveLength(3)

        handlers.onFulfilled({ config: configs[1] })
        handlers.onFulfilled({ config: configs[2] })
        await Promise.all(requestPromises)
        expect(limiter.active).toBe(0)
    })

    it('releases the slot when a request fails', async () => {
        const { instance, handlers } = mockAxios()
        const limiter = installConcurrencyLimit(instance, { limit: 1 })
        const config = { url: '/fail' }

        await handlers.onRequest(config)
        expect(limiter.active).toBe(1)

        await expect(handlers.onRejected({ config, response: { status: 500 } })).rejects.toMatchObject({
            response: { status: 500 },
        })
        expect(limiter.active).toBe(0)
    })
})

describe('memoizeAsync', () => {
    it('shares one in-flight promise for the same key', async () => {
        let starts = 0
        const load = memoizeAsync(async (key: string) => {
            starts++
            await new Promise((resolve) => setTimeout(resolve, 10))
            return `value:${key}`
        })

        const [a, b] = await Promise.all([load('x'), load('x')])
        expect(a).toBe('value:x')
        expect(b).toBe('value:x')
        expect(starts).toBe(1)
    })

    it('retries after a rejected load', async () => {
        let attempts = 0
        const load = memoizeAsync(async () => {
            attempts++
            if (attempts === 1) {
                throw new Error('boom')
            }
            return 'ok'
        })

        await expect(load('k')).rejects.toThrow('boom')
        await expect(load('k')).resolves.toBe('ok')
        expect(attempts).toBe(2)
    })
})
