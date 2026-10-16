/** Default worker count for independent ISC reads within one operation invocation. */
export const DEFAULT_ISC_CONCURRENCY = 5

export interface ConcurrencyLimiter {
    /** Runs `fn` when a slot is free. Nested calls each need their own slot. */
    run<T>(fn: () => Promise<T>): Promise<T>
    /** Active in-flight count (for tests). */
    readonly active: number
    /** Queued waiters (for tests). */
    readonly waiting: number
}

/**
 * Shared permit pool for one invocation.
 */
export function createConcurrencyLimiter(limit: number): ConcurrencyLimiter {
    const max = Math.max(1, limit)
    let active = 0
    const waiters: Array<() => void> = []

    const acquire = (): Promise<void> => {
        if (active < max) {
            active++
            return Promise.resolve()
        }
        return new Promise<void>((resolve) => {
            waiters.push(() => {
                active++
                resolve()
            })
        })
    }

    const release = (): void => {
        active--
        const next = waiters.shift()
        if (next) {
            next()
        }
    }

    return {
        get active() {
            return active
        },
        get waiting() {
            return waiters.length
        },
        async run<T>(fn: () => Promise<T>): Promise<T> {
            await acquire()
            try {
                return await fn()
            } finally {
                release()
            }
        },
    }
}

/**
 * Runs `run` over `items` with at most `limit` concurrent workers.
 * Results keep input order. An empty list returns immediately.
 */
export async function mapWithConcurrency<T, R>(
    items: readonly T[],
    limit: number,
    run: (item: T, index: number) => Promise<R>
): Promise<R[]> {
    if (items.length === 0) {
        return []
    }

    const workerCount = Math.max(1, Math.min(limit, items.length))
    let next = 0
    const results = new Array<R>(items.length)
    const workers = Array.from({ length: workerCount }, async () => {
        while (next < items.length) {
            const index = next++
            results[index] = await run(items[index], index)
        }
    })
    await Promise.all(workers)
    return results
}

/**
 * Memoizes async work by key for the lifetime of the returned function.
 * Concurrent callers for the same key share one in-flight promise.
 */
export function memoizeAsync<T>(load: (key: string) => Promise<T>): (key: string) => Promise<T> {
    const cache = new Map<string, Promise<T>>()
    return (key: string): Promise<T> => {
        const cached = cache.get(key)
        if (cached) {
            return cached
        }
        const pending = load(key).catch((error) => {
            cache.delete(key)
            throw error
        })
        cache.set(key, pending)
        return pending
    }
}

/** Structural subset of axios used by {@link installConcurrencyLimit}. */
export interface ConcurrentAxiosInstance {
    interceptors: {
        request: {
            use: (
                onFulfilled: (config: Record<string, unknown>) => unknown | Promise<unknown>,
                onRejected?: (error: unknown) => unknown
            ) => unknown
        }
        response: {
            use: (onFulfilled: (value: never) => unknown, onRejected: (error: unknown) => Promise<unknown>) => unknown
        }
    }
}

/**
 * Caps in-flight HTTP requests on a shared Axios instance. Nested risk and SoD fan-out share this
 * budget so concurrent work cannot stampede the tenant.
 *
 * Register AFTER {@link installThrottleRetry}: on 429 the concurrency interceptor releases its
 * slot first (response handlers run in reverse registration order), then throttle sleeps and
 * re-issues via `instance.request`, which acquires a fresh slot.
 */
export function installConcurrencyLimit(
    instance: ConcurrentAxiosInstance,
    options: { limit?: number } = {}
): ConcurrencyLimiter {
    const limiter = createConcurrencyLimiter(options.limit ?? DEFAULT_ISC_CONCURRENCY)

    instance.interceptors.request.use(async (config) => {
        // Park the Axios request until a permit is held; keep the permit until response.
        await new Promise<void>((ready, reject) => {
            void limiter
                .run(async () => {
                    await new Promise<void>((releasePermit) => {
                        ;(config as { __iscRelease?: () => void }).__iscRelease = releasePermit
                        ready()
                    })
                })
                .catch(reject)
        })
        return config
    })

    const releaseSlot = (config: Record<string, unknown> | undefined): void => {
        const releasePermit = config?.__iscRelease as (() => void) | undefined
        if (releasePermit) {
            delete config!.__iscRelease
            releasePermit()
        }
    }

    instance.interceptors.response.use(
        (response) => {
            releaseSlot((response as { config?: Record<string, unknown> }).config)
            return response
        },
        async (error: unknown) => {
            releaseSlot((error as { config?: Record<string, unknown> } | undefined)?.config)
            throw error
        }
    )

    return limiter
}
