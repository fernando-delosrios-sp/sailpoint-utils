#!/usr/bin/env node
/**
 * Ensures dist/index.js registers every command declared in connector-spec.json.
 * Catches codegen/build drift before pack-zip upload.
 */
import connectorSpec from '../connector-spec.json'

async function verifyBundle(): Promise<void> {
    const distPath = require.resolve('../dist/index.js')
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const module = require(distPath) as { connector?: () => Promise<{ handlers: Map<string, unknown> }> }

    if (typeof module.connector !== 'function') {
        throw new Error('[verify:bundle] dist/index.js must export async function connector()')
    }

    const connector = await module.connector()
    const missing = connectorSpec.commands.filter((command) => !connector.handlers.has(command))

    if (missing.length > 0) {
        throw new Error(
            `[verify:bundle] dist/index.js is missing handlers for: ${missing.join(', ')}\n` +
                'Run npm run build and retry. If handlers are still missing, check src/operations/auto-registry.ts.'
        )
    }

    console.log(`[verify:bundle] OK — ${connectorSpec.commands.length} commands registered in dist/index.js`)
}

if (require.main === module) {
    verifyBundle().catch((error) => {
        console.error(error instanceof Error ? error.message : String(error))
        process.exit(1)
    })
}

export { verifyBundle }
