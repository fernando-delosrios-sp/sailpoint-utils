import { readFileSync } from 'fs'
import { resolve } from 'path'
import { CommandHandler } from '@sailpoint/connector-sdk'
import { beginFixtureOutputCapture, endFixtureOutputCapture } from '../src/framework/test-mode-fixture-collector'
import { exampleOperation } from '../src/operations/example-operation'
import { sodRemediationOperation } from '../src/operations/sod-remediation-operation'
import { formatFixtureOutputSummary, printFixtureOutputSummary } from './fixture-output'

/** JSON envelope for local operation dry-runs. Config is optional for offline SPCX_TEST_MODE runs. */
export interface OperationFixture {
    command: string
    config?: Record<string, unknown>
    input: Record<string, unknown>
}

const REQUIRED_CONFIG_FIELDS = ['apiUrl', 'token', 'sourceName'] as const

/** Normalizes common fixture config mistakes before handler invocation. */
export function normalizeFixtureConfig(config?: Record<string, unknown>): Record<string, unknown> | undefined {
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

const COMMAND_HANDLERS: Record<string, CommandHandler> = {
    'custom:example': exampleOperation,
    'custom:sod-remediation': sodRemediationOperation,
}

function formatFixtureFailure(fixturePath: string, fixture: OperationFixture | undefined, error: unknown): string {
    const lines = ['', 'Fixture run failed', `  file: ${fixturePath}`]
    if (fixture) {
        lines.push(`  command: ${fixture.command}`)
        if (fixture.input.requestId != null) {
            lines.push(`  requestId: ${String(fixture.input.requestId)}`)
        }
    }

    const message = error instanceof Error ? error.message : String(error)
    lines.push('', `Error: ${message}`)

    if (/Missing required config fields/.test(message)) {
        const missing = REQUIRED_CONFIG_FIELDS.filter(
            (field) => fixture?.config?.[field] == null || fixture?.config?.[field] === ''
        )
        if (missing.length > 0) {
            lines.push(`  missing: ${missing.join(', ')}`)
        }
        lines.push(
            '',
            'Hint: config must include apiUrl, token, and sourceName.',
            '  Use "apiUrl" (not "url"). Add "testMode": true to inhibit persist writes.',
            '  For config-less dry runs: fixtures/sod-remediation-offline.json'
        )
    } else if (/401|403|status code 401|status code 403/.test(message)) {
        lines.push(
            '',
            'Hint: replace config.token with a valid ISC access token.',
            '  Keep "testMode": true to avoid writing accounts while testing.',
            '  For config-less dry runs: fixtures/sod-remediation-offline.json'
        )
    } else if (/Experimental API|violations\/v1|controls\/v1/.test(message)) {
        lines.push(
            '',
            'Hint: verify violationId exists and the token has experimental API scopes.',
            '  For local handler smoke test without ISC: fixtures/sod-remediation-offline.json'
        )
    }

    lines.push('')
    return lines.join('\n')
}

/** Loads and validates a fixture file from disk. */
export function loadFixture(filePath: string): OperationFixture {
    const absolutePath = resolve(filePath)
    const raw = readFileSync(absolutePath, 'utf-8')
    const parsed = JSON.parse(raw) as Partial<OperationFixture>

    if (!parsed.command) {
        throw new Error('Fixture missing required field: command')
    }

    return {
        command: parsed.command,
        config: normalizeFixtureConfig(parsed.config),
        input: parsed.input ?? {},
    }
}

/** Invokes a registered custom command handler and returns captured outputs. */
export async function runFixture(
    fixture: OperationFixture,
    handlers: Record<string, CommandHandler> = COMMAND_HANDLERS
): Promise<{ response: unknown; inhibitedPersists: ReturnType<typeof endFixtureOutputCapture> }> {
    const handler = handlers[fixture.command]
    if (!handler) {
        throw new Error(`Unknown command: ${fixture.command}`)
    }

    const previousTestMode = process.env.SPCX_TEST_MODE
    const autoTestMode = fixture.config === undefined
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
        commandType: fixture.command,
    }
    if (fixture.config !== undefined) {
        context.config = fixture.config
    }

    let inhibitedPersists: ReturnType<typeof endFixtureOutputCapture> = []

    try {
        beginFixtureOutputCapture()
        await handler(context as never, fixture.input, res as never)
    } finally {
        inhibitedPersists = endFixtureOutputCapture()
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

/** Runs fixture from path; returns process exit code (0 success, 1 failure). */
export async function runFixtureFromPath(fixturePath: string): Promise<number> {
    let fixture: OperationFixture | undefined
    try {
        fixture = loadFixture(fixturePath)
        const result = await runFixture(fixture)
        printFixtureOutputSummary({
            ...result,
            command: fixture.command,
            requestId: fixture.input.requestId,
            testMode: fixture.config?.testMode === true || fixture.config === undefined,
        })
        return 0
    } catch (error) {
        console.error(formatFixtureFailure(fixturePath, fixture, error))
        return 1
    }
}

async function main(): Promise<void> {
    const fixturePath = process.argv[2]
    if (!fixturePath) {
        console.error('Usage: npm run test:operation -- <fixture.json>')
        process.exit(1)
    }

    process.exit(await runFixtureFromPath(fixturePath))
}

if (require.main === module) {
    main()
}

