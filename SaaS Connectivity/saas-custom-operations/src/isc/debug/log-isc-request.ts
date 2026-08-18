import { getActiveFrameworkLogger, sanitizeForLog } from '../../framework/logger'

/** Emits structured ISC request debug lines to connector stdout. */
export function logIscDebug(label: string, details: Record<string, unknown>): void {
    getActiveFrameworkLogger().info(`[isc-debug] ${label}`, sanitizeForLog(details))
}

/** Logs axios/SDK API failures with response payload when present. */
export function logIscRequestFailure(label: string, error: unknown): void {
    if (typeof error !== 'object' || error === null) {
        getActiveFrameworkLogger().info(`[isc-debug] ${label} failed`, String(error))
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
