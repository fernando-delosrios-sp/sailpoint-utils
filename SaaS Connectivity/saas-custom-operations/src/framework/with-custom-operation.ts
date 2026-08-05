import { CommandHandler, ConnectorError, Context, readConfig, Response } from '@sailpoint/connector-sdk'
import { createRequestContext, RequestContextDependencies } from './request-context'
import { StandardInput } from './types'

const CONFIG_FIELDS = ['apiUrl', 'token', 'sourceId'] as const
const INPUT_STANDARD_FIELDS = ['requestId'] as const

/** Resolves standard fields from an invoke payload's `config` and `input` sections. */
export function parseStandardInput(
    config: Record<string, unknown>,
    input: Record<string, unknown>
): { standard: StandardInput; operationInput: Record<string, unknown> } {
    const missingConfig = CONFIG_FIELDS.filter((field) => config[field] == null || config[field] === '')
    if (missingConfig.length > 0) {
        throw new ConnectorError(`Missing required config fields: ${missingConfig.join(', ')}`)
    }

    const missingInput = INPUT_STANDARD_FIELDS.filter((field) => input[field] == null || input[field] === '')
    if (missingInput.length > 0) {
        throw new ConnectorError(`Missing required input fields: ${missingInput.join(', ')}`)
    }

    const standard: StandardInput = {
        apiUrl: String(config.apiUrl),
        token: String(config.token),
        sourceId: String(config.sourceId),
        requestId: String(input.requestId),
    }

    const operationInput = { ...input }
    for (const field of INPUT_STANDARD_FIELDS) {
        delete operationInput[field]
    }

    return { standard, operationInput }
}

export type CustomOperationHandler<T extends Record<string, unknown> = Record<string, unknown>> = (
    ctx: ReturnType<typeof createRequestContext>,
    input: T
) => Promise<void> | void

/**
 * Wraps a custom command handler with volatile RequestContext initialization.
 * Parses invoke payload shape: config (apiUrl, token, sourceId) + input (requestId, operation fields).
 */
export function withCustomOperation<T extends Record<string, unknown>>(
    handler: CustomOperationHandler<T>,
    deps: RequestContextDependencies = {}
): CommandHandler {
    return async (context: Context, input: Record<string, unknown>, res: Response<any>) => {
        const config = deps.config ?? (await readConfig())
        const { standard, operationInput } = parseStandardInput(config, input)
        const requestContext = createRequestContext(standard, res, deps)

        console.log(`[${standard.requestId}] custom operation started: ${context.commandType}`)

        await handler(requestContext, operationInput as T)

        console.log(`[${standard.requestId}] custom operation completed`)
    }
}
