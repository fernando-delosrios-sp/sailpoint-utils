import { CommandHandler, ConnectorError, Context, readConfig, Response } from '@sailpoint/connector-sdk'
import { InferOperationInput, InferOperationOutput, OperationSignature } from './output-schema'
import { getOperationSchema } from './operation-schema-registry'
import { createRequestContext, RequestContextDependencies } from './request-context'
import { createSailPointClients } from './sdk-factory'
import {
    resolveSourceByName,
    resolveSourceByNameReadOnly,
    verifyIscStatus,
} from './source-provisioning'
import { hasAccessToken, isTestMode, TEST_MODE_PLACEHOLDER_SOURCE_ID } from './test-mode'
import { OperationSchemaContract, RequestContext, StandardInput } from './types'

const CONFIG_FIELDS = ['apiUrl', 'token', 'sourceName'] as const
const INPUT_STANDARD_FIELDS = ['requestId'] as const

type ContextWithConfig = Context & { config?: Record<string, unknown> }

/** Strips workflow/PAT copy-paste artifacts before SDK clients add `Authorization: Bearer`. */
export function normalizeAccessToken(token: string): string {
    return token.trim().replace(/^Bearer\s+/i, '')
}

export interface ParseStandardInputOptions {
    testMode?: boolean
}

/** Resolves standard fields from an invoke payload's `config` and `input` sections. */
export function parseStandardInput(
    config: Record<string, unknown>,
    input: Record<string, unknown>,
    options: ParseStandardInputOptions = {}
): { standard: StandardInput; operationInput: Record<string, unknown> } {
    const testMode = options.testMode ?? isTestMode(config)
    const offline = testMode && !hasAccessToken(config)

    if (offline) {
        const missingInput = INPUT_STANDARD_FIELDS.filter((field) => input[field] == null || input[field] === '')
        if (missingInput.length > 0) {
            throw new ConnectorError(`Missing required input fields: ${missingInput.join(', ')}`)
        }

        const standard: StandardInput = {
            apiUrl: config.apiUrl != null ? String(config.apiUrl).trim() : '',
            token: '',
            sourceName: config.sourceName != null ? String(config.sourceName).trim() : TEST_MODE_PLACEHOLDER_SOURCE_ID,
            requestId: String(input.requestId).trim(),
        }

        const operationInput = { ...input }
        for (const field of INPUT_STANDARD_FIELDS) {
            delete operationInput[field]
        }

        return { standard, operationInput }
    }

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
    /** Explicit schema sidecar; overrides registry lookup for auto-discovered operations. */
    operationSchema?: OperationSchemaContract
}

/**
 * Wraps a custom command handler with volatile RequestContext initialization.
 * Resolves sourceName to sourceId and attaches operation output fields for schema reconciliation.
 * Auto-discovered operations resolve `operationSchema` from the build-time registry when omitted.
 */
export function customOperation<T extends OperationSignature>(
    handler: CustomOperationHandler<T>,
    deps: CustomOperationOptions = {}
): CommandHandler {
    return async (context: Context, input: Record<string, unknown>, res: Response<any>) => {
        const contextConfig = (context as ContextWithConfig).config
        const config = deps.config ?? contextConfig ?? (await readConfig())
        const testMode = isTestMode(config)
        const { standard, operationInput } = parseStandardInput(config, input, { testMode })

        let sdk = deps.sdk
        let sourceId = deps.sourceId
        let inhibitedPersistCount = 0

        if (testMode) {
            console.log(`[test-mode] active command=${context.commandType} requestId=${standard.requestId}`)

            if (hasAccessToken(config)) {
                sdk = sdk ?? createSailPointClients(standard.apiUrl, standard.token)
                await verifyIscStatus(sdk.sources)
                console.log(`[test-mode] ISC status check succeeded`)

                if (!sourceId) {
                    const resolved = await resolveSourceByNameReadOnly(sdk.sources, standard.sourceName)
                    if (resolved) {
                        sourceId = resolved
                    } else {
                        console.warn(
                            `[test-mode] source "${standard.sourceName}" not found — using placeholder ${TEST_MODE_PLACEHOLDER_SOURCE_ID}`
                        )
                        sourceId = TEST_MODE_PLACEHOLDER_SOURCE_ID
                    }
                }
            } else {
                console.log(`[test-mode] offline — skipping all ISC API calls`)
                sourceId = sourceId ?? TEST_MODE_PLACEHOLDER_SOURCE_ID
            }
        } else {
            sdk = sdk ?? createSailPointClients(standard.apiUrl, standard.token)
            sourceId = sourceId ?? (await resolveSourceByName(sdk.sources, standard.sourceName, standard.token))
        }

        const resolvedSchema =
            deps.operationSchema ??
            (context.commandType ? getOperationSchema(context.commandType) : undefined)
        const operationSchema: OperationSchemaContract | undefined = resolvedSchema
            ? {
                  command: resolvedSchema.command ?? context.commandType,
                  outputFields: resolvedSchema.outputFields,
              }
            : undefined

        const requestContext = createRequestContext<InferOperationOutput<T>>(standard, res, {
            ...deps,
            sdk,
            sourceId,
            operationSchema,
            testMode,
            onTestModePersist: testMode ? () => inhibitedPersistCount++ : undefined,
        })

        console.log(`[${standard.requestId}] custom operation started: ${context.commandType}`)

        await handler(requestContext, operationInput as InferOperationInput<T>)

        if (testMode) {
            console.log(
                `[test-mode] completed requestId=${standard.requestId} inhibitedPersists=${inhibitedPersistCount}`
            )
        }

        console.log(`[${standard.requestId}] custom operation completed`)
    }
}
