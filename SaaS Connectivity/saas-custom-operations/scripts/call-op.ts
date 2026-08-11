import { readFileSync } from 'fs'
import { resolve } from 'path'
import { CommandHandler } from '@sailpoint/connector-sdk'
import { beginPayloadOutputCapture, endPayloadOutputCapture } from '../src/framework/payload-persist-collector'
import { exampleOperation } from '../src/operations/example/index'
import { sodRemediationOperation } from '../src/operations/sod-remediation/index'
import { formatPayloadOutputSummary, printPayloadOutputSummary } from './payload-output'

/** JSON invoke envelope for local operation runs. Config is optional for offline SPCX_TEST_MODE runs. */
export interface InvokePayload {
    type: string
    config?: Record<string, unknown>
    input: Record<string, unknown>
}

const REQUIRED_CONFIG_FIELDS = ['apiUrl', 'token', 'sourceName'] as const

/** Normalizes common payload config mistakes before handler invocation. */
export function normalizePayloadConfig(config?: Record<string, unknown>): Record<string, unknown> | undefined {
    if (!config) {
        return undefined
    }

    const normalized = { ...config }
    if ((normalized.apiUrl == null || normalized.apiUrl === '') && typeof normalized.url === 'string') {
        normalized.apiUrl = normalized.url
        delete normalized.url
    }
    return normalized
}

const OPERATION_HANDLERS: Record<string, CommandHandler> = {
    'custom:example': exampleOperation,
    'custom:sod-remediation': sodRemediationOperation,
}

function formatPayloadFailure(payloadPath: string, payload: InvokePayload | undefined, error: unknown): string {
    const lines = ['', 'Local invoke failed', `  file: ${payloadPath}`]
    if (payload) {
        lines.push(`  type: ${payload.type}`)
        if (payload.input.requestId != null) {
            lines.push(`  requestId: ${String(payload.input.requestId)}`)
        }
    }

    const message = error instanceof Error ? error.message : String(error)
    lines.push('', `Error: ${message}`)

    if (/Missing required config fields/.test(message)) {
        const missing = REQUIRED_CONFIG_FIELDS.filter(
            (field) => payload?.config?.[field] == null || payload?.config?.[field] === ''
        )
        if (missing.length > 0) {
            lines.push(`  missing: ${missing.join(', ')}`)
        }
        lines.push(
            '',
            'Hint: config must include apiUrl, token, and sourceName.',
            '  Use "apiUrl" (not "url"). Add "testMode": true to inhibit persist writes.',
            '  For config-less dry runs: payloads/sod-remediation-offline.json'
        )
    } else if (/401|403|status code 401|status code 403/.test(message)) {
        lines.push(
            '',
            'Hint: replace config.token with a valid ISC access token.',
            '  Keep "testMode": true to avoid writing accounts while testing.',
            '  For config-less dry runs: payloads/sod-remediation-offline.json'
        )
    } else if (/Experimental API|violations\/v1|controls\/v1/.test(message)) {
        lines.push(
            '',
            'Hint: verify violationId exists and the token has experimental API scopes.',
            '  For local handler smoke test without ISC: payloads/sod-remediation-offline.json'
        )
    }

    lines.push('')
    return lines.join('\n')
}

/** Loads and validates an invoke payload file from disk. */
export function loadPayload(filePath: string): InvokePayload {
    const absolutePath = resolve(filePath)
    const raw = readFileSync(absolutePath, 'utf-8')
    const parsed = JSON.parse(raw) as Partial<InvokePayload>

    if (!parsed.type) {
        throw new Error('Payload missing required field: type')
    }

    return {
        type: parsed.type,
        config: normalizePayloadConfig(parsed.config),
        input: parsed.input ?? {},
    }
}

/** Invokes a registered custom command handler and returns captured outputs. */
export async function runPayload(
    payload: InvokePayload,
    handlers: Record<string, CommandHandler> = OPERATION_HANDLERS
): Promise<{ response: unknown; inhibitedPersists: ReturnType<typeof endPayloadOutputCapture> }> {
    const handler = handlers[payload.type]
    if (!handler) {
        throw new Error(`Unknown operation type: ${payload.type}`)
    }

    const previousTestMode = process.env.SPCX_TEST_MODE
    const autoTestMode = payload.config === undefined
    if (autoTestMode) {
        process.env.SPCX_TEST_MODE = '1'
    }

    let responsePayload: unknown
    const res = {
        send: (payload: unknown) => {
            responsePayload = payload
        },
    }

    const context: { commandType: string; config?: Record<string, unknown> } = {
        commandType: payload.type,
    }
    if (payload.config !== undefined) {
        context.config = payload.config
    }

    let inhibitedPersists: ReturnType<typeof endPayloadOutputCapture> = []

    try {
        beginPayloadOutputCapture()
        await handler(context as never, payload.input, res as never)
    } finally {
        inhibitedPersists = endPayloadOutputCapture()
        if (autoTestMode) {
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    }

    return { response: responsePayload, inhibitedPersists }
}

/** Runs payload from path; returns process exit code (0 success, 1 failure). */
export async function runPayloadFromPath(payloadPath: string): Promise<number> {
    let payload: InvokePayload | undefined
    try {
        payload = loadPayload(payloadPath)
        const result = await runPayload(payload)
        const failed =
            result.response != null &&
            typeof result.response === 'object' &&
            (result.response as { status?: unknown }).status === 'failed'

        if (failed) {
            const errorMessage = String((result.response as { error?: unknown }).error ?? 'operation failed')
            console.error(formatPayloadFailure(payloadPath, payload, new Error(errorMessage)))
            return 1
        }

        printPayloadOutputSummary({
            ...result,
            type: payload.type,
            requestId: payload.input.requestId,
            testMode: payload.config?.testMode === true || payload.config === undefined,
        })
        return 0
    } catch (error) {
        console.error(formatPayloadFailure(payloadPath, payload, error))
        return 1
    }
}

async function main(): Promise<void> {
    const payloadPath = process.argv[2]
    if (!payloadPath) {
        console.error('Usage: npm run call:op -- <payload.json>')
        process.exit(1)
    }

    process.exit(await runPayloadFromPath(payloadPath))
}

if (require.main === module) {
    main()
}

