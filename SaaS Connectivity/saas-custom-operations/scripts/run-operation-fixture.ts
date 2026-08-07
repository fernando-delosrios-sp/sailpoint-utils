import { readFileSync } from 'fs'
import { resolve } from 'path'
import { CommandHandler } from '@sailpoint/connector-sdk'
import { beginFixtureOutputCapture, endFixtureOutputCapture } from '../src/framework/test-mode-fixture-collector'
import { exampleOperation } from '../src/operations/example-operation'
import { formatFixtureOutputSummary, printFixtureOutputSummary } from './fixture-output'

/** JSON envelope for local operation dry-runs. Config is optional for offline SPCX_TEST_MODE runs. */
export interface OperationFixture {
    command: string
    config?: Record<string, unknown>
    input: Record<string, unknown>
}

const COMMAND_HANDLERS: Record<string, CommandHandler> = {
    'custom:example': exampleOperation,
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
        config: parsed.config,
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
    try {
        const result = await runFixture(loadFixture(fixturePath))
        printFixtureOutputSummary(result)
        return 0
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error)
        console.error(message)
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
