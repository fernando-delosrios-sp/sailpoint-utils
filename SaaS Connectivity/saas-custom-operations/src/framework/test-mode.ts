import { readConfig } from '@sailpoint/connector-sdk'

export const TEST_MODE_PLACEHOLDER_SOURCE_ID = 'test-mode-local'

/** True when config.testMode is true or SPCX_TEST_MODE=1 (unless explicitly false). */
export function isTestMode(config: Record<string, unknown>): boolean {
    if (config.testMode === false) {
        return false
    }
    if (config.testMode === true) {
        return true
    }
    return process.env.SPCX_TEST_MODE === '1'
}

export interface ResolvedInvocationConfig {
    config: Record<string, unknown>
    configProvided: boolean
}

type ConfigSource = { config?: Record<string, unknown> }

/** Resolves invoke config and whether an explicit config object was supplied. */
export async function resolveInvocationConfig(
    deps: ConfigSource,
    context: ConfigSource,
    readConfigFn: () => Promise<Record<string, unknown>> = readConfig
): Promise<ResolvedInvocationConfig> {
    if (deps.config !== undefined) {
        return { config: deps.config, configProvided: true }
    }

    if (context.config !== undefined) {
        return { config: context.config, configProvided: true }
    }

    try {
        const config = await readConfigFn()
        const configProvided = Object.keys(config).length > 0
        return { config, configProvided }
    } catch {
        return { config: {}, configProvided: false }
    }
}
