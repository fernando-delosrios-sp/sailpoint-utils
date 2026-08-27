import { inspect, type InspectOptions } from 'node:util'

export type LogLevel = 'info' | 'warn' | 'error'

/** Named detail map for structured invoke-scoped logs (objects, arrays, scalars). */
export interface FrameworkLogger {
    info(message: string, detail?: Record<string, unknown>): void
    warn(message: string, detail?: Record<string, unknown>): void
    error(message: string, detail?: Record<string, unknown>): void
}

export interface FrameworkLogEvent {
    timestamp: string
    level: LogLevel
    requestId: string
    command?: string
    message: string
    detail?: Record<string, unknown>
}

export interface CreateFrameworkLoggerOptions {
    requestId: string
    command?: string
    logUrl?: string
    now?: () => Date
    fetchImpl?: typeof fetch
    consoleImpl?: Pick<Console, 'log' | 'warn' | 'error'>
}

export interface EmitLogEventOptions extends CreateFrameworkLoggerOptions {
    /** When set, writes this body to console instead of pretty multiline layout. */
    consoleBodyOverride?: string
    /** When true, skips stdout (POST only when logUrl is set). */
    skipConsole?: boolean
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

/**
 * Normalizes a detail map for JSON encoding: omits undefined/function/symbol values,
 * replaces circular refs with `[Circular]`, serializes Error instances, stringifies bigint.
 */
export function normalizeDetailForJson(detail: Record<string, unknown>): Record<string, unknown> {
    const seen = new WeakSet<object>()

    const normalizeValue = (value: unknown): unknown => {
        if (value === undefined || typeof value === 'function' || typeof value === 'symbol') {
            return undefined
        }
        if (value === null) {
            return null
        }
        if (typeof value === 'bigint') {
            return value.toString()
        }
        if (value instanceof Error) {
            return {
                name: value.name,
                message: value.message,
                stack: value.stack,
            }
        }
        if (typeof value !== 'object') {
            return value
        }

        if (seen.has(value)) {
            return '[Circular]'
        }
        seen.add(value)

        if (Array.isArray(value)) {
            return value.map(normalizeValue)
        }

        const normalized: Record<string, unknown> = {}
        for (const [key, entry] of Object.entries(value as Record<string, unknown>)) {
            const normalizedEntry = normalizeValue(entry)
            if (normalizedEntry !== undefined) {
                normalized[key] = normalizedEntry
            }
        }
        return normalized
    }

    const normalizedDetail: Record<string, unknown> = {}
    for (const [key, entry] of Object.entries(detail)) {
        const normalizedEntry = normalizeValue(entry)
        if (normalizedEntry !== undefined) {
            normalizedDetail[key] = normalizedEntry
        }
    }
    return normalizedDetail
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

/** Formats stdout log output: headline plus labeled per-key detail blocks. */
export function formatPrettyConsoleLines(
    requestId: string,
    message: string,
    detail?: Record<string, unknown>
): string[] {
    const lines = [`[${requestId}] ${message}`]
    if (detail === undefined) {
        return lines
    }

    for (const [key, value] of Object.entries(detail)) {
        if (value !== null && typeof value === 'object') {
            const inspected = inspect(value, consoleInspectOptions())
            lines.push(`  ${key}:`)
            for (const inspectedLine of inspected.split('\n')) {
                lines.push(`    ${inspectedLine}`)
            }
        } else {
            lines.push(`  ${key}: ${String(value)}`)
        }
    }

    return lines
}

function postLogEvent(logUrl: string, event: FrameworkLogEvent, fetchImpl: typeof fetch): void {
    void fetchImpl(logUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(event),
    }).catch(() => {})
}

function buildFrameworkLogEvent(
    level: LogLevel,
    requestId: string,
    message: string,
    command: string | undefined,
    detail: Record<string, unknown> | undefined,
    now: () => Date
): FrameworkLogEvent {
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
        event.detail = detail
    }
    return event
}

/** Shared emit path: redact → JSON-safe normalize → console → optional POST. */
export function emitLogEvent(
    level: LogLevel,
    message: string,
    detail: Record<string, unknown> | undefined,
    options: EmitLogEventOptions
): void {
    const {
        requestId,
        command,
        logUrl,
        now = () => new Date(),
        fetchImpl = fetch,
        consoleImpl = console,
        consoleBodyOverride,
        skipConsole = false,
    } = options

    const sanitizedDetail =
        detail !== undefined ? (sanitizeForLog(detail) as Record<string, unknown>) : undefined
    const normalizedDetail =
        sanitizedDetail !== undefined ? normalizeDetailForJson(sanitizedDetail) : undefined

    if (!skipConsole) {
        const consoleOutput =
            consoleBodyOverride !== undefined
                ? consoleBodyOverride
                : formatPrettyConsoleLines(requestId, message, normalizedDetail).join('\n')
        if (level === 'warn') {
            consoleImpl.warn(consoleOutput)
        } else if (level === 'error') {
            consoleImpl.error(consoleOutput)
        } else {
            consoleImpl.log(consoleOutput)
        }
    }

    if (logUrl) {
        const event = buildFrameworkLogEvent(level, requestId, message, command, normalizedDetail, now)
        postLogEvent(logUrl, event, fetchImpl)
    }
}

/** POSTs one external log event without writing to console (legacy helper — prefer emitLogEvent). */
export function postFrameworkLogEvent(
    options: Pick<CreateFrameworkLoggerOptions, 'requestId' | 'command' | 'logUrl' | 'now' | 'fetchImpl'>,
    level: LogLevel,
    message: string,
    detail?: Record<string, unknown>
): void {
    emitLogEvent(level, message, detail, {
        ...options,
        skipConsole: true,
    })
}

/** Creates a dual-sink logger: always console, optionally fire-and-forget POST to logUrl. */
export function createFrameworkLogger(options: CreateFrameworkLoggerOptions): FrameworkLogger {
    const emit = (level: LogLevel, message: string, detail?: Record<string, unknown>): void => {
        emitLogEvent(level, message, detail, options)
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
