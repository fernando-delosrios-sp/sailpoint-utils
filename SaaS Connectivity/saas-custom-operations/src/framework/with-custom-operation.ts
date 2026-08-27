import { CommandHandler, ConnectorError, Context, Response } from '@sailpoint/connector-sdk'
import { buildErrorLogDetail, toConnectorError } from './connector-error'
import { createFrameworkLogger, getActiveFrameworkLogger, resolveLogUrlFromConfig, setActiveFrameworkLogger } from './logger'
import { persistFailedResult } from './failure-persist'
import {
    clearInFlightInvocation,
    getInFlightInvocation,
    invocationDedupeKey,
    isFailedCommandOutput,
    startKeepAlive,
    stopKeepAlive,
    trackInFlightInvocation,
    type InvocationOutcome,
} from './invocation-guard'
import {
    InferOperationInput,
    InferOperationOutput,
    InferOperationResponse,
    OperationSignature,
} from './output-schema'
import { getOperationSchema } from './operation-schema-registry'
import { createRequestContext, RequestContextDependencies } from './request-context'
import { createSailPointClients } from './sdk-factory'
import {
    resolveSourceByName,
    resolveSourceByNameReadOnly,
} from './result-source'
import { verifyIscStatus } from '../isc/sources'
import { isTestMode, resolveInvocationConfig, TEST_MODE_PLACEHOLDER_SOURCE_ID } from './test-mode'
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
    configProvided?: boolean
}

/** Resolves standard fields from an invoke payload's `config` and `input` sections. */
export function parseStandardInput(
    config: Record<string, unknown>,
    input: Record<string, unknown>,
    options: ParseStandardInputOptions = {}
): { standard: StandardInput; operationInput: Record<string, unknown> } {
    const testMode = options.testMode ?? isTestMode(config)
    const noConfigOffline = testMode && options.configProvided === false

    if (noConfigOffline) {
        const missingInput = INPUT_STANDARD_FIELDS.filter((field) => input[field] == null || input[field] === '')
        if (missingInput.length > 0) {
            throw new ConnectorError(`Missing required input fields: ${missingInput.join(', ')}`)
        }

        const standard: StandardInput = {
            apiUrl: '',
            token: '',
            sourceName: TEST_MODE_PLACEHOLDER_SOURCE_ID,
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
    ctx: RequestContext<InferOperationOutput<T>, InferOperationResponse<T>>,
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
 * Failures are normalized via {@link toConnectorError} and returned as `{ status: 'failed', error }`
 * (HTTP 200) so calling workflows do not retry on spcx/platform 500s — unless the handler already sent a response.
 * Terminal failures also upsert a result account with `status: failed` and `details` when request context is available.
 */
export function customOperation<T extends OperationSignature>(
    handler: CustomOperationHandler<T>,
    deps: CustomOperationOptions = {}
): CommandHandler {
    return async (context: Context, input: Record<string, unknown>, res: Response<any>) => {
        const dedupeKey = invocationDedupeKey(context.commandType, input)
        if (dedupeKey) {
            const inFlight = getInFlightInvocation(dedupeKey)
            if (inFlight) {
                const requestId = String(input.requestId).trim()
                getActiveFrameworkLogger(requestId).info(
                    `duplicate invoke — awaiting in-flight ${context.commandType ?? 'custom operation'}`
                )
                const outcome = await inFlight
                res.send(
                    outcome.status === 'success'
                        ? { status: 'success' }
                        : { status: 'failed', error: outcome.error ?? 'Operation failed' }
                )
                return
            }
        }

        let responseSent = false
        let outcome: InvocationOutcome = { status: 'success' }
        let activeCtx: RequestContext<InferOperationOutput<T>, InferOperationResponse<T>> | undefined
        let pendingFailurePersist: Promise<void> | undefined

        const trackedRes: Response<any> = {
            send(output: unknown) {
                responseSent = true
                if (isFailedCommandOutput(output)) {
                    outcome = { status: 'failed', error: output.error }
                    pendingFailurePersist = persistFailedResult(activeCtx?.requestId, output.error, activeCtx)
                } else {
                    outcome = { status: 'success' }
                }
                res.send(output)
            },
            saveState: (state) => res.saveState(state),
            keepAlive: () => res.keepAlive(),
            patchConfig: (patches) => res.patchConfig(patches),
        }

        let keepAliveTimer: ReturnType<typeof setInterval> | undefined

        const invocation = (async (): Promise<InvocationOutcome> => {
            keepAliveTimer = startKeepAlive(trackedRes)

            try {
                await runCustomOperation(context, input, trackedRes, handler, deps, (ctx) => {
                    activeCtx = ctx
                })
                await pendingFailurePersist
                return outcome
            } catch (e) {
                const error = toConnectorError(e, context.commandType)
                getActiveFrameworkLogger(String(input.requestId ?? 'unknown')).error(
                    error.message,
                    buildErrorLogDetail(e)
                )
                if (!responseSent) {
                    trackedRes.send({ status: 'failed', error: error.message })
                }
                await pendingFailurePersist
                return outcome
            } finally {
                stopKeepAlive(keepAliveTimer)
                setActiveFrameworkLogger(undefined)
            }
        })()

        if (dedupeKey) {
            trackInFlightInvocation(dedupeKey, invocation)
        }

        try {
            await invocation
        } finally {
            if (dedupeKey) {
                clearInFlightInvocation(dedupeKey)
            }
        }
    }
}

async function runCustomOperation<T extends OperationSignature>(
    context: Context,
    input: Record<string, unknown>,
    res: Response<any>,
    handler: CustomOperationHandler<T>,
    deps: CustomOperationOptions,
    onContext?: (ctx: RequestContext<InferOperationOutput<T>, InferOperationResponse<T>>) => void
): Promise<void> {
        const { config, configProvided } = await resolveInvocationConfig(deps, context as ContextWithConfig)
        const testMode = configProvided ? isTestMode(config) : isTestMode({})
        const { standard, operationInput } = parseStandardInput(config, input, { testMode, configProvided })
        const logUrl = resolveLogUrlFromConfig(config)
        const log = createFrameworkLogger({
            requestId: standard.requestId,
            command: context.commandType,
            logUrl,
        })
        setActiveFrameworkLogger(log)

        const resolvedSchema =
            deps.operationSchema ??
            (context.commandType ? getOperationSchema(context.commandType) : undefined)
        const outputFields = resolvedSchema?.outputFields ?? []

        let sdk = deps.sdk
        let sourceId = deps.sourceId
        let inhibitedPersistCount = 0

        if (testMode) {
            log.info(`[test-mode] active command=${context.commandType} requestId=${standard.requestId}`)

            if (configProvided) {
                sdk = sdk ?? createSailPointClients(standard.apiUrl, standard.token)
                await verifyIscStatus(sdk.sources)
                log.info(`[test-mode] ISC status check succeeded`)

                if (!sourceId) {
                    const resolved = await resolveSourceByNameReadOnly(sdk.sources, standard.sourceName)
                    if (resolved) {
                        sourceId = resolved
                    } else {
                        log.warn(
                            `[test-mode] source "${standard.sourceName}" not found — using placeholder ${TEST_MODE_PLACEHOLDER_SOURCE_ID}`
                        )
                        sourceId = TEST_MODE_PLACEHOLDER_SOURCE_ID
                    }
                }
            } else {
                log.info(`[test-mode] no config — skipping ISC`)
                sourceId = sourceId ?? TEST_MODE_PLACEHOLDER_SOURCE_ID
            }
        } else {
            sdk = sdk ?? createSailPointClients(standard.apiUrl, standard.token)
            sourceId =
                sourceId ??
                (await resolveSourceByName(sdk.sources, standard.sourceName, standard.token, outputFields))
        }

        const operationSchema: OperationSchemaContract | undefined = resolvedSchema
            ? {
                  command: resolvedSchema.command ?? context.commandType,
                  outputFields: resolvedSchema.outputFields,
              }
            : undefined

        const requestContext = createRequestContext<
            InferOperationOutput<T>,
            InferOperationResponse<T>
        >(standard, res, {
            ...deps,
            sdk,
            sourceId,
            operationSchema,
            testMode,
            onTestModePersist: testMode ? () => inhibitedPersistCount++ : undefined,
            logger: log,
            logUrl,
            command: context.commandType,
        })

        onContext?.(requestContext)

        log.info(`custom operation started: ${context.commandType}`)

        await handler(requestContext, operationInput as InferOperationInput<T>)

        if (testMode) {
            log.info(`[test-mode] completed requestId=${standard.requestId} inhibitedPersists=${inhibitedPersistCount}`)
        }

        log.info('custom operation completed')
}


