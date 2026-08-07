import { readFileSync } from 'fs'
import { resolve } from 'path'
import { CommandHandler } from '@sailpoint/connector-sdk'
import { exampleOperation } from '../src/operations/example-operation'

/** JSON envelope for local operation dry-runs (`command`, `config`, `input`). */
export interface OperationFixture {
    command: string
    config: Record<string, unknown>
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
        config: parsed.config ?? {},
        input: parsed.input ?? {},
    }
}

/** Invokes a registered custom command handler and returns the res.send payload. */
export async function runFixture(fixture: OperationFixture): Promise<unknown> {
    const handler = COMMAND_HANDLERS[fixture.command]
    if (!handler) {
        throw new Error(`Unknown command: ${fixture.command}`)
    }

    let responsePayload: unknown
    const res = {
        send: (payload: unknown) => {
            responsePayload = payload
        },
    }

    await handler({ commandType: fixture.command, config: fixture.config } as never, fixture.input, res as never)

    return responsePayload
}

/** Runs fixture from path; returns process exit code (0 success, 1 failure). */
export async function runFixtureFromPath(fixturePath: string): Promise<number> {
    try {
        const payload = await runFixture(loadFixture(fixturePath))
        console.log(JSON.stringify(payload, null, 2))
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
