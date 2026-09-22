const DEFAULT_MAX_RETRIES = 4
const DEFAULT_BASE_DELAY_MS = 1_000
const DEFAULT_MAX_DELAY_MS = 20_000
const THROTTLED_STATUS = 429
const ATTEMPT_KEY = '__throttleRetryAttempt'

/** Structural subset of the axios instance this module drives, so axios stays a transitive dependency. */
export interface RetryingAxiosInstance {
    interceptors: {
        response: {
            use: (
                onFulfilled: (value: never) => unknown,
                onRejected: (error: unknown) => Promise<unknown>
            ) => unknown
        }
    }
    request: (config: Record<string, unknown>) => Promise<unknown>
}

export interface ThrottleRetryOptions {
    /** Retries attempted after the first throttled response. */
    maxRetries?: number
    baseDelayMs?: number
    maxDelayMs?: number
    /** Override for tests to avoid real delays during retry loops. */
    sleep?: (ms: number) => Promise<void>
    onRetry?: (info: { attempt: number; delayMs: number; url?: string }) => void
}

export interface ResolveThrottleDelayParams {
    headers?: Record<string, unknown>
    /** 1 for the first retry, 2 for the second, and so on. */
    retryNumber: number
    baseDelayMs?: number
    maxDelayMs?: number
    now?: Date
}

async function defaultSleep(ms: number): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, ms))
}

function readHeader(headers: Record<string, unknown> | undefined, name: string): string | undefined {
    if (!headers) {
        return undefined
    }

    const match = Object.keys(headers).find((key) => key.toLowerCase() === name)
    const value = match === undefined ? undefined : headers[match]
    return typeof value === 'string' || typeof value === 'number' ? String(value) : undefined
}

/**
 * ISC answers a throttled request with `Retry-After`, as either a seconds count or an HTTP date. Without
 * the header the wait doubles per retry, which is what spreads a long catalog scan back under the limit.
 */
export function resolveThrottleDelayMs(params: ResolveThrottleDelayParams): number {
    const baseDelayMs = params.baseDelayMs ?? DEFAULT_BASE_DELAY_MS
    const maxDelayMs = params.maxDelayMs ?? DEFAULT_MAX_DELAY_MS
    const retryAfter = readHeader(params.headers, 'retry-after')

    let delayMs: number
    if (retryAfter !== undefined && /^\d+$/.test(retryAfter.trim())) {
        delayMs = Number(retryAfter.trim()) * 1_000
    } else if (retryAfter !== undefined && !Number.isNaN(Date.parse(retryAfter))) {
        const now = params.now ?? new Date()
        delayMs = Math.max(0, Date.parse(retryAfter) - now.getTime())
    } else {
        delayMs = baseDelayMs * 2 ** (params.retryNumber - 1)
    }

    return Math.min(delayMs, maxDelayMs)
}

function throttledResponse(error: unknown): { status: number; headers?: Record<string, unknown> } | undefined {
    const response = (error as { response?: { status?: unknown; headers?: unknown } } | undefined)?.response
    if (!response || response.status !== THROTTLED_STATUS) {
        return undefined
    }

    return {
        status: THROTTLED_STATUS,
        headers: (response.headers as Record<string, unknown> | undefined) ?? undefined,
    }
}

/**
 * Retries throttled requests on the shared axios instance. The SDK installs `axios-retry` with its own
 * defaults, which cover network errors and 5xx but not 429, so one throttled call otherwise fails the
 * whole operation.
 */
export function installThrottleRetry(instance: RetryingAxiosInstance, options: ThrottleRetryOptions = {}): void {
    const maxRetries = options.maxRetries ?? DEFAULT_MAX_RETRIES
    const sleep = options.sleep ?? defaultSleep

    instance.interceptors.response.use(
        (response) => response,
        async (error: unknown) => {
            const response = throttledResponse(error)
            const config = (error as { config?: Record<string, unknown> } | undefined)?.config
            if (!response || !config) {
                throw error
            }

            const attempt = Number(config[ATTEMPT_KEY] ?? 0) + 1
            if (attempt > maxRetries) {
                throw error
            }
            config[ATTEMPT_KEY] = attempt

            const delayMs = resolveThrottleDelayMs({
                headers: response.headers,
                retryNumber: attempt,
                baseDelayMs: options.baseDelayMs,
                maxDelayMs: options.maxDelayMs,
            })

            options.onRetry?.({
                attempt,
                delayMs,
                url: typeof config.url === 'string' ? config.url : undefined,
            })

            await sleep(delayMs)
            return instance.request(config)
        }
    )
}
