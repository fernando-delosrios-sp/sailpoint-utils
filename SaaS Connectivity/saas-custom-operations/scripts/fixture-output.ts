import { formatSpreadJson } from '../src/framework/pretty-json'
import type { InhibitedPersistRecord } from '../src/framework/test-mode-fixture-collector'

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

export interface FixtureOutputSummary {
    response: unknown
    inhibitedPersists: InhibitedPersistRecord[]
    command?: string
    requestId?: unknown
    testMode?: boolean
}

function formatSection(title: string, body: string): string {
    const rule = dim('─'.repeat(72))
    return [rule, bold(cyan(title)), rule, body, rule].join('\n')
}

/** Formats fixture operation outputs for terminal display. */
export function formatFixtureOutputSummary(summary: FixtureOutputSummary): string {
    const sections: string[] = ['']

    const headerParts = [
        summary.command ? `command=${summary.command}` : undefined,
        summary.requestId != null ? `requestId=${String(summary.requestId)}` : undefined,
        summary.testMode ? 'testMode=true' : undefined,
    ].filter(Boolean)

    if (headerParts.length > 0) {
        sections.push(formatSection('Fixture run', `${bold('Status:')} ${cyan('success')}\n${headerParts.join('  ')}`))
        sections.push('')
    }

    if (summary.inhibitedPersists.length > 0) {
        sections.push(
            formatSection(
                'Inhibited persist outputs (would-be ISC accounts)',
                formatSpreadJson(summary.inhibitedPersists)
            )
        )
        sections.push('')
    } else if (summary.testMode === false) {
        sections.push(
            formatSection(
                'Persist outputs',
                dim('No inhibited persists captured — testMode was false; accounts may have been written to ISC.')
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

/** Prints highlighted fixture operation outputs to stdout. */
export function printFixtureOutputSummary(summary: FixtureOutputSummary): void {
    console.log(formatFixtureOutputSummary(summary))
}


