const DEFAULT_MAX_RETRIES = 4
const DEFAULT_BASE_DELAY_MS = 1_000
const DEFAULT_MAX_BACKOFF_MS = 20_000
/** Refuse to wait longer than this for a server Retry-After; surface the 429 instead. */
const DEFAULT_MAX_RETRY_AFTER_MS = 60_000
const THROTTLED_STATUS = 429
const ATTEMPT_KEY = '__throttleRetryAttempt'
const COOLDOWN_KEY = '__throttleCooldownUntil'

/** Structural subset of the axios instance this module drives, so axios stays a transitive dependency. */
export interface RetryingAxiosInstance {
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
    request: (config: Record<string, unknown>) => Promise<unknown>
    /** Shared cooldown end time (epoch ms) set when any request is throttled. */
    [COOLDOWN_KEY]?: number
}

export interface ThrottleRetryOptions {
    /** Retries attempted after the first throttled response. */
    maxRetries?: number
    baseDelayMs?: number
    /** Cap for exponential backoff when Retry-After is absent. Does not shorten a server Retry-After. */
    maxBackoffMs?: number
    /** Cap for exponential backoff (alias of maxBackoffMs for existing call sites). */
    maxDelayMs?: number
    /**
     * Maximum wait accepted for a server-provided Retry-After. Longer values fail the request
     * instead of retrying earlier than the tenant instructed.
     */
    maxRetryAfterMs?: number
    /** 0–1 fraction of the backoff delay used as random jitter. Defaults to 0.2. */
    jitterRatio?: number
    /** Override for tests to avoid real delays during retry loops. */
    sleep?: (ms: number) => Promise<void>
    /** Override for tests to make jitter deterministic. */
    random?: () => number
    /** Override for tests. */
    now?: () => number
    onRetry?: (info: { attempt: number; delayMs: number; url?: string }) => void
}

export interface ResolveThrottleDelayParams {
    headers?: Record<string, unknown>
    /** 1 for the first retry, 2 for the second, and so on. */
    retryNumber: number
    baseDelayMs?: number
    maxBackoffMs?: number
    maxDelayMs?: number
    maxRetryAfterMs?: number
    jitterRatio?: number
    random?: () => number
    now?: Date
}

export interface ThrottleDelayResult {
    delayMs: number
    /** True when the server Retry-After exceeds maxRetryAfterMs and the caller must not retry. */
    reject?: boolean
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

function applyJitter(delayMs: number, jitterRatio: number, random: () => number): number {
    if (delayMs <= 0 || jitterRatio <= 0) {
        return delayMs
    }
    const spread = delayMs * jitterRatio
    return Math.max(0, Math.round(delayMs - spread / 2 + random() * spread))
}

/**
 * ISC answers a throttled request with `Retry-After`, as either a seconds count or an HTTP date.
 * Without the header the wait doubles per retry with jitter. A server-provided Retry-After is never
 * shortened; if it exceeds maxRetryAfterMs the result asks the caller to reject.
 */
export function resolveThrottleDelayMs(params: ResolveThrottleDelayParams): number {
    return resolveThrottleDelay(params).delayMs
}

/** Full delay decision including whether an excessive Retry-After should abort the retry. */
export function resolveThrottleDelay(params: ResolveThrottleDelayParams): ThrottleDelayResult {
    const baseDelayMs = params.baseDelayMs ?? DEFAULT_BASE_DELAY_MS
    const maxBackoffMs = params.maxBackoffMs ?? params.maxDelayMs ?? DEFAULT_MAX_BACKOFF_MS
    const maxRetryAfterMs = params.maxRetryAfterMs ?? DEFAULT_MAX_RETRY_AFTER_MS
    const jitterRatio = params.jitterRatio ?? 0.2
    const random = params.random ?? Math.random
    const retryAfter = readHeader(params.headers, 'retry-after')

    if (retryAfter !== undefined && /^\d+$/.test(retryAfter.trim())) {
        const delayMs = Number(retryAfter.trim()) * 1_000
        if (delayMs > maxRetryAfterMs) {
            return { delayMs, reject: true }
        }
        return { delayMs }
    }

    if (retryAfter !== undefined && !Number.isNaN(Date.parse(retryAfter))) {
        const now = params.now ?? new Date()
        const delayMs = Math.max(0, Date.parse(retryAfter) - now.getTime())
        if (delayMs > maxRetryAfterMs) {
            return { delayMs, reject: true }
        }
        return { delayMs }
    }

    const backoff = Math.min(baseDelayMs * 2 ** (params.retryNumber - 1), maxBackoffMs)
    return { delayMs: applyJitter(backoff, jitterRatio, random) }
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
 *
 * A shared cooldown pauses new requests after any 429 until the latest known retry time, so concurrent
 * workers do not continue a retry storm while one request is backing off.
 */
export function installThrottleRetry(instance: RetryingAxiosInstance, options: ThrottleRetryOptions = {}): void {
    const maxRetries = options.maxRetries ?? DEFAULT_MAX_RETRIES
    const sleep = options.sleep ?? defaultSleep
    const now = options.now ?? Date.now

    instance.interceptors.request.use(async (config) => {
        const cooldownUntil = instance[COOLDOWN_KEY] ?? 0
        const waitMs = cooldownUntil - now()
        if (waitMs > 0) {
            await sleep(waitMs)
        }
        return config
    })

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

            const decision = resolveThrottleDelay({
                headers: response.headers,
                retryNumber: attempt,
                baseDelayMs: options.baseDelayMs,
                maxBackoffMs: options.maxBackoffMs ?? options.maxDelayMs,
                maxRetryAfterMs: options.maxRetryAfterMs,
                jitterRatio: options.jitterRatio,
                random: options.random,
            })

            if (decision.reject) {
                throw error
            }

            config[ATTEMPT_KEY] = attempt
            const delayMs = decision.delayMs
            instance[COOLDOWN_KEY] = Math.max(instance[COOLDOWN_KEY] ?? 0, now() + delayMs)

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
