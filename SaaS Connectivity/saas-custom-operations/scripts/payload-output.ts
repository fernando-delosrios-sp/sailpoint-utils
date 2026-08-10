import { formatSpreadJson } from '../src/framework/pretty-json'
import type { InhibitedPersistRecord } from '../src/framework/payload-persist-collector'

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

export { formatSpreadJson } from '../src/framework/pretty-json'

export interface PayloadOutputSummary {
    response: unknown
    inhibitedPersists: InhibitedPersistRecord[]
    type?: string
    requestId?: unknown
    testMode?: boolean
}

function formatSection(title: string, body: string): string {
    const rule = dim('─'.repeat(72))
    return [rule, bold(cyan(title)), rule, body, rule].join('\n')
}

/** Formats local invoke outputs for terminal display. */
export function formatPayloadOutputSummary(summary: PayloadOutputSummary): string {
    const sections: string[] = ['']

    const headerParts = [
        summary.type ? `type=${summary.type}` : undefined,
        summary.requestId != null ? `requestId=${String(summary.requestId)}` : undefined,
        summary.testMode ? 'testMode=true' : undefined,
    ].filter(Boolean)

    if (headerParts.length > 0) {
        sections.push(formatSection('Local invoke', `${bold('Status:')} ${cyan('success')}\n${headerParts.join('  ')}`))
        sections.push('')
    }

    if (summary.inhibitedPersists.length > 0) {
        sections.push(
            formatSection(
                'Simulated persist (testMode=true)',
                formatSpreadJson(summary.inhibitedPersists)
            )
        )
        sections.push('')
    } else if (summary.testMode === false) {
        sections.push(
            formatSection(
                'Persist outputs',
                dim('No simulated persists captured — testMode was false; accounts may have been written to ISC.')
            )
        )
        sections.push('')
    }

    sections.push(
        formatSection('Operation response (ctx.res.send)', formatSpreadJson(summary.response ?? null))
    )

    if (summary.inhibitedPersists.length > 0) {
        const primary = summary.inhibitedPersists.find((record) => !String(record.identity).includes(':'))
        if (primary?.attributes) {
            sections.push('')
            sections.push(
                formatSection(
                    'Persisted operation output (primary identity)',
                    formatSpreadJson(primary.attributes)
                )
            )
        }
    }

    sections.push('')

    return sections.join('\n')
}

/** Prints highlighted local invoke outputs to stdout. */
export function printPayloadOutputSummary(summary: PayloadOutputSummary): void {
    console.log(formatPayloadOutputSummary(summary))
}
