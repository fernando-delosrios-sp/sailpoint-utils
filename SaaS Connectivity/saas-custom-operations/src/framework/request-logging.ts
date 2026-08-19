import { CommandHandler, Connector, Context, Response } from '@sailpoint/connector-sdk'
import { readInvokeConfig } from './invoke-config'
import { emitLogEvent, resolveLogUrlFromConfig, sanitizeForLog } from './logger'
import { formatSpreadJson } from './pretty-json'

function useColor(): boolean {
    return Boolean(process.stdout.isTTY && !process.env.NO_COLOR)
}

function bold(text: string): string {
    return useColor() ? `\x1b[1m${text}\x1b[0m` : text
}

function cyan(text: string): string {
    return useColor() ? `\x1b[36m${text}\x1b[0m` : text
}

function dim(text: string): string {
    return useColor() ? `\x1b[2m${text}\x1b[0m` : text
}

function formatSection(title: string, body: string): string {
    const rule = dim('─'.repeat(72))
    return [rule, bold(cyan(title)), rule, body, rule].join('\n')
}

/** Resolves invoke config for logging from context or runtime config sources. */
export async function resolveConfigForRequestLogging(
    context: Context & { config?: Record<string, unknown> }
): Promise<Record<string, unknown> | undefined> {
    if (context.config != null && typeof context.config === 'object') {
        return context.config
    }

    return readInvokeConfig()
}

/** Masks sensitive config values before logging invoke payloads. */
export function redactConfigForLogging(config: Record<string, unknown> | undefined): Record<string, unknown> | undefined {
    if (!config) {
        return undefined
    }

    return sanitizeForLog(config) as Record<string, unknown>
}

export interface IncomingRequestSummary {
    type: string
    config?: Record<string, unknown>
    input: Record<string, unknown>
}

/** Formats an invoke payload for terminal display (payload-style). */
export function formatIncomingRequest(summary: IncomingRequestSummary): string {
    const headerParts = [
        `type=${summary.type}`,
        summary.input.requestId != null ? `requestId=${String(summary.input.requestId)}` : undefined,
        summary.config?.testMode === true ? 'testMode=true' : undefined,
    ].filter(Boolean)

    const payload: Record<string, unknown> = {
        type: summary.type,
        input: summary.input,
    }
    const redactedConfig = redactConfigForLogging(summary.config)
    if (redactedConfig !== undefined) {
        payload.config = redactedConfig
    }

    return ['', formatSection('Incoming request', `${headerParts.join('  ')}\n\n${formatSpreadJson(payload)}`), ''].join('\n')
}

/** Logs an invoke payload through the shared framework emit path. */
export function printIncomingRequest(summary: IncomingRequestSummary): void {
    const formatted = formatIncomingRequest(summary)
    const requestId = summary.input.requestId != null ? String(summary.input.requestId).trim() : 'unknown'
    const logUrl = resolveLogUrlFromConfig(summary.config)

    emitLogEvent(
        'info',
        'Incoming request',
        {
            command: summary.type,
            input: summary.input,
            ...(summary.config !== undefined ? { config: summary.config } : {}),
        },
        {
            requestId,
            command: summary.type,
            logUrl,
            consoleBodyOverride: formatted,
        }
    )
}

type ContextWithConfig = Context & { config?: Record<string, unknown> }

/** Wraps a command handler to log the resolved invoke payload before execution. */
export function withRequestLogging(command: string, handler: CommandHandler): CommandHandler {
    return async (context: Context, input: Record<string, unknown>, res: Response<any>) => {
        const config = await resolveConfigForRequestLogging(context as ContextWithConfig)
        const summary: IncomingRequestSummary = {
            type: command,
            input,
            config,
        }
        printIncomingRequest(summary)
        await handler(context, input, res)
    }
}

/** Patches connector.command so every registered handler logs incoming requests. */
export function wrapConnectorWithRequestLogging(connector: Connector): Connector {
    const originalCommand = connector.command.bind(connector)
    return Object.assign(connector, {
        command(type: string, handler: CommandHandler) {
            return originalCommand(type, withRequestLogging(type, handler))
        },
    })
}
