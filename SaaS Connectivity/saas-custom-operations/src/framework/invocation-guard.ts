import { Response } from '@sailpoint/connector-sdk'

/** Platform invoke timeout guard — ping before typical connector HTTP deadlines. */
export const KEEP_ALIVE_INTERVAL_MS = 20_000

export type InvocationOutcome = {
    status: 'success' | 'failed'
    error?: string
}

const inFlightInvocations = new Map<string, Promise<InvocationOutcome>>()

/** Clears in-flight dedupe state (Vitest only). */
export function clearInFlightInvocationsForTests(): void {
    inFlightInvocations.clear()
}

const APPLY_COMMAND = 'custom:access-model-sod-remediation-apply'

/** Builds a dedupe key from command type and workflow requestId (or formInstanceId for apply). */
export function invocationDedupeKey(commandType: string | undefined, input: Record<string, unknown>): string | undefined {
    if (!commandType) {
        return undefined
    }

    if (commandType === APPLY_COMMAND) {
        const formInstanceId = input.formInstanceId
        if (formInstanceId == null || String(formInstanceId).trim() === '') {
            return undefined
        }
        return `${commandType}:${String(formInstanceId).trim()}`
    }

    const requestId = input.requestId
    if (requestId == null || requestId === '') {
        return undefined
    }

    return `${commandType}:${String(requestId).trim()}`
}

export function getInFlightInvocation(key: string): Promise<InvocationOutcome> | undefined {
    return inFlightInvocations.get(key)
}

export function trackInFlightInvocation(key: string, promise: Promise<InvocationOutcome>): void {
    inFlightInvocations.set(key, promise)
}

export function clearInFlightInvocation(key: string): void {
    inFlightInvocations.delete(key)
}

export function isFailedCommandOutput(output: unknown): output is { status: 'failed'; error: string } {
    return (
        typeof output === 'object' &&
        output !== null &&
        (output as { status?: unknown }).status === 'failed' &&
        typeof (output as { error?: unknown }).error === 'string'
    )
}

/** Starts periodic keepAlive pings so long-running handlers avoid platform timeout retries. */
export function startKeepAlive(res: Response<any>): ReturnType<typeof setInterval> | undefined {
    try {
        res.keepAlive()
    } catch {
        return undefined
    }

    return setInterval(() => {
        try {
            res.keepAlive()
        } catch {
            // Local mocks or closed streams may not support keepAlive.
        }
    }, KEEP_ALIVE_INTERVAL_MS)
}

export function stopKeepAlive(timer: ReturnType<typeof setInterval> | undefined): void {
    if (timer) {
        clearInterval(timer)
    }
}
