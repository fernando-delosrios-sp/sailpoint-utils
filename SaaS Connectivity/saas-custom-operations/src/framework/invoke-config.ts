import { createRequire } from 'module'
import { join } from 'path'
import { readConfig } from '@sailpoint/connector-sdk'

function isConfigRecord(value: unknown): value is Record<string, unknown> {
    return value != null && typeof value === 'object' && !Array.isArray(value)
}

/** Reads invoke config from the spcx/node_modules SDK (AsyncLocalStorage used by local dev server). */
export async function readExternalInvokeConfig(): Promise<Record<string, unknown> | undefined> {
    try {
        const requireFromProject = createRequire(join(process.cwd(), 'package.json'))
        const sdk = requireFromProject('@sailpoint/connector-sdk') as {
            readConfig?: () => Promise<unknown>
        }
        if (typeof sdk.readConfig !== 'function') {
            return undefined
        }

        const config = await sdk.readConfig()
        return isConfigRecord(config) && Object.keys(config).length > 0 ? config : undefined
    } catch {
        return undefined
    }
}

/** Reads invoke config from spcx AsyncLocalStorage or the bundled CONNECTOR_CONFIG runtime path. */
export async function readInvokeConfig(): Promise<Record<string, unknown> | undefined> {
    const externalConfig = await readExternalInvokeConfig()
    if (externalConfig) {
        return externalConfig
    }

    try {
        const bundledConfig = await readConfig()
        return isConfigRecord(bundledConfig) && Object.keys(bundledConfig).length > 0 ? bundledConfig : undefined
    } catch {
        return undefined
    }
}
