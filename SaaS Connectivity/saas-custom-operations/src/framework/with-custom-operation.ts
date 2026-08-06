import { CommandHandler, ConnectorError, Context, readConfig, Response } from '@sailpoint/connector-sdk'
import { InferOperationInput, InferOperationOutput, OperationSignature } from './output-schema'
import { createRequestContext, RequestContextDependencies } from './request-context'
import { createSailPointClients } from './sdk-factory'
import { resolveSourceByName } from './source-provisioning'
import { OperationSchemaContract, RequestContext, StandardInput } from './types'

const CONFIG_FIELDS = ['apiUrl', 'token', 'sourceName'] as const
const INPUT_STANDARD_FIELDS = ['requestId'] as const

/** Strips workflow/PAT copy-paste artifacts before SDK clients add `Authorization: Bearer`. */
export function normalizeAccessToken(token: string): string {
    return token.trim().replace(/^Bearer\s+/i, '')
}

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
        apiUrl: String(config.apiUrl).trim(),
        token: normalizeAccessToken(String(config.token)),
        sourceName: String(config.sourceName).trim(),
        requestId: String(input.requestId).trim(),
    }

    const operationInput = { ...input }
    for (const field of INPUT_STANDARD_FIELDS) {
        delete operationInput[field]
    }

    return { standard, operationInput }
}

export type CustomOperationHandler<T extends OperationSignature> = (
    ctx: RequestContext<InferOperationOutput<T>>,
    input: InferOperationInput<T>
) => Promise<void> | void

export interface CustomOperationOptions extends RequestContextDependencies {
    operationSchema?: OperationSchemaContract
}

/**
 * Wraps a custom command handler with volatile RequestContext initialization.
 * Resolves sourceName to sourceId and attaches operation output fields for schema reconciliation.
 */
export function customOperation<T extends OperationSignature>(
    handler: CustomOperationHandler<T>,
    deps: CustomOperationOptions = {}
): CommandHandler {
    return async (context: Context, input: Record<string, unknown>, res: Response<any>) => {
        const config = deps.config ?? (await readConfig())
        const { standard, operationInput } = parseStandardInput(config, input)

        const sdk = deps.sdk ?? createSailPointClients(standard.apiUrl, standard.token)
        const sourceId =
            deps.sourceId ?? (await resolveSourceByName(sdk.sources, standard.sourceName, standard.token))

        const operationSchema: OperationSchemaContract | undefined = deps.operationSchema
            ? {
                  command: deps.operationSchema.command ?? context.commandType,
                  outputFields: deps.operationSchema.outputFields,
              }
            : undefined

        const requestContext = createRequestContext<InferOperationOutput<T>>(standard, res, {
            ...deps,
            sdk,
            sourceId,
            operationSchema,
        })

        console.log(`[${standard.requestId}] custom operation started: ${context.commandType}`)

        await handler(requestContext, operationInput as InferOperationInput<T>)

        console.log(`[${standard.requestId}] custom operation completed`)
    }
}
