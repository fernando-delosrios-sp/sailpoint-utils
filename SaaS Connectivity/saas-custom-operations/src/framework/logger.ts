import { inspect, type InspectOptions } from 'node:util'

export type LogLevel = 'info' | 'warn' | 'error'

export interface FrameworkLogger {
    info(message: string, detail?: unknown): void
    warn(message: string, detail?: unknown): void
    error(message: string, detail?: unknown): void
}

export interface FrameworkLogEvent {
    timestamp: string
    level: LogLevel
    requestId: string
    command?: string
    message: string
    detail?: unknown
}

export interface CreateFrameworkLoggerOptions {
    requestId: string
    command?: string
    logUrl?: string
    now?: () => Date
    fetchImpl?: typeof fetch
    consoleImpl?: Pick<Console, 'log' | 'warn' | 'error'>
}

const REDACTED = '[REDACTED]'

function redactToken(value: string): string {
    if (value.length <= 12) {
        return REDACTED
    }
    return `${value.slice(0, 6)}…${value.slice(-4)}`
}

/** Redacts tokens, bearer values, and sensitive keys before external log delivery. */
export function sanitizeForLog(value: unknown): unknown {
    if (value === null || value === undefined) {
        return value
    }
    if (typeof value === 'string') {
        if (/^Bearer\s+/i.test(value) || value.length > 40) {
            return redactToken(value.replace(/^Bearer\s+/i, ''))
        }
        return value
    }
    if (Array.isArray(value)) {
        return value.map(sanitizeForLog)
    }
    if (typeof value === 'object') {
        const record = value as Record<string, unknown>
        const sanitized: Record<string, unknown> = {}
        for (const [key, entry] of Object.entries(record)) {
            if (/token|authorization|secret|password/i.test(key)) {
                sanitized[key] = REDACTED
            } else {
                sanitized[key] = sanitizeForLog(entry)
            }
        }
        return sanitized
    }
    return value
}

/** Resolves optional logUrl from invoke config (trimmed; empty treated as unset). */
export function resolveLogUrlFromConfig(config: Record<string, unknown> | undefined): string | undefined {
    if (!config || config.logUrl == null) {
        return undefined
    }

    const trimmed = String(config.logUrl).trim()
    return trimmed.length > 0 ? trimmed : undefined
}

function consoleInspectOptions(): InspectOptions {
    return {
        depth: null,
        breakLength: Infinity,
        colors: Boolean(process.stdout.isTTY && !process.env.NO_COLOR),
    }
}

function formatConsoleLine(requestId: string, message: string, detail?: unknown): string {
    if (detail === undefined) {
        return `[${requestId}] ${message}`
    }

    const inspected = inspect(detail, consoleInspectOptions())
    return `[${requestId}] ${message} ${inspected}`
}

function postLogEvent(
    logUrl: string,
    event: FrameworkLogEvent,
    fetchImpl: typeof fetch
): void {
    void fetchImpl(logUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(event),
    }).catch(() => {})
}

/** POSTs one external log event without writing to console (incoming request section uses its own format). */
export function postFrameworkLogEvent(
    options: Pick<CreateFrameworkLoggerOptions, 'requestId' | 'command' | 'logUrl' | 'now' | 'fetchImpl'>,
    level: LogLevel,
    message: string,
    detail?: unknown
): void {
    const { requestId, command, logUrl, now = () => new Date(), fetchImpl = fetch } = options
    if (!logUrl) {
        return
    }

    const event: FrameworkLogEvent = {
        timestamp: now().toISOString(),
        level,
        requestId,
        message,
    }
    if (command) {
        event.command = command
    }
    if (detail !== undefined) {
        event.detail = sanitizeForLog(detail)
    }
    postLogEvent(logUrl, event, fetchImpl)
}

/** Creates a dual-sink logger: always console, optionally fire-and-forget POST to logUrl. */
export function createFrameworkLogger(options: CreateFrameworkLoggerOptions): FrameworkLogger {
    const {
        requestId,
        command,
        logUrl,
        now = () => new Date(),
        fetchImpl = fetch,
        consoleImpl = console,
    } = options

    const emit = (level: LogLevel, message: string, detail?: unknown): void => {
        const consoleLine = formatConsoleLine(requestId, message, detail)
        if (level === 'warn') {
            consoleImpl.warn(consoleLine)
        } else if (level === 'error') {
            consoleImpl.error(consoleLine)
        } else {
            consoleImpl.log(consoleLine)
        }

        if (logUrl) {
            const event: FrameworkLogEvent = {
                timestamp: now().toISOString(),
                level,
                requestId,
                message,
            }
            if (command) {
                event.command = command
            }
            if (detail !== undefined) {
                event.detail = sanitizeForLog(detail)
            }
            postLogEvent(logUrl, event, fetchImpl)
        }
    }

    return {
        info: (message, detail) => emit('info', message, detail),
        warn: (message, detail) => emit('warn', message, detail),
        error: (message, detail) => emit('error', message, detail),
    }
}

let activeFrameworkLogger: FrameworkLogger | undefined

/** Sets the logger for the current custom operation invocation (cleared in finally). */
export function setActiveFrameworkLogger(logger: FrameworkLogger | undefined): void {
    activeFrameworkLogger = logger
}

/** Returns the active invocation logger, or a console-only fallback when unset. */
export function getActiveFrameworkLogger(requestId = 'unknown'): FrameworkLogger {
    if (activeFrameworkLogger) {
        return activeFrameworkLogger
    }

    return createFrameworkLogger({ requestId })
}
