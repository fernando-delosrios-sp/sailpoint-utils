function redactToken(value: string): string {
    if (value.length <= 12) {
        return '<REDACTED>'
    }
    return `${value.slice(0, 6)}…${value.slice(-4)}`
}

function sanitizeForLog(value: unknown): unknown {
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
                sanitized[key] = '<REDACTED>'
            } else {
                sanitized[key] = sanitizeForLog(entry)
            }
        }
        return sanitized
    }
    return value
}

/** Emits structured ISC request debug lines to connector stdout. */
export function logIscDebug(label: string, details: Record<string, unknown>): void {
    console.log(`[isc-debug] ${label}`, JSON.stringify(sanitizeForLog(details)))
}

/** Logs axios/SDK API failures with response payload when present. */
export function logIscRequestFailure(label: string, error: unknown): void {
    if (typeof error !== 'object' || error === null) {
        console.log(`[isc-debug] ${label} failed`, String(error))
        return
    }

    const candidate = error as {
        message?: string
        status?: number
        statusText?: string
        data?: unknown
        code?: string
        config?: { method?: string; url?: string; params?: unknown; data?: unknown }
        response?: { status?: number; statusText?: string; data?: unknown }
    }

    logIscDebug(`${label} failed`, {
        message: candidate.message,
        status: candidate.status ?? candidate.response?.status,
        statusText: candidate.statusText ?? candidate.response?.statusText,
        code: candidate.code,
        request: candidate.config
            ? {
                  method: candidate.config.method,
                  url: candidate.config.url,
                  params: candidate.config.params,
                  data: candidate.config.data,
              }
            : undefined,
        responseBody: candidate.data ?? candidate.response?.data,
    })
}
