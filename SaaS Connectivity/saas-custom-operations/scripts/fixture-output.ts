import type { InhibitedPersistRecord } from '../src/framework/test-mode-fixture-collector'

const INDENT = 4

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

/** Pretty JSON with blank lines between top-level object properties. */
export function formatSpreadJson(value: unknown, indent = INDENT): string {
    const json = JSON.stringify(value, null, indent)
    if (value === null || typeof value !== 'object' || Array.isArray(value)) {
        return json
    }

    const lines = json.split('\n')
    const spaced: string[] = []

    for (let index = 0; index < lines.length; index++) {
        spaced.push(lines[index])

        const line = lines[index]
        const next = lines[index + 1]
        const isTopLevelProperty =
            /^\s{4}"[^"]+":/.test(line) && !/^\s{4}"[^"]+": \{/.test(line) && !/^\s{4}"[^"]+": \[$/.test(line)
        const nextClosesObject = next === `${' '.repeat(indent - 4)}}`

        if (isTopLevelProperty && next && !nextClosesObject) {
            spaced.push('')
        }
    }

    return spaced.join('\n')
}

export interface FixtureOutputSummary {
    response: unknown
    inhibitedPersists: InhibitedPersistRecord[]
}

function formatSection(title: string, body: string): string {
    const rule = dim('─'.repeat(72))
    return [rule, bold(cyan(title)), rule, body, rule].join('\n')
}

/** Formats fixture operation outputs for terminal display. */
export function formatFixtureOutputSummary(summary: FixtureOutputSummary): string {
    const sections: string[] = ['']

    if (summary.inhibitedPersists.length > 0) {
        sections.push(
            formatSection(
                'Inhibited persist outputs (would-be ISC accounts)',
                formatSpreadJson(summary.inhibitedPersists)
            )
        )
        sections.push('')
    }

    sections.push(
        formatSection('Operation response (ctx.res.send)', formatSpreadJson(summary.response ?? null))
    )
    sections.push('')

    return sections.join('\n')
}

/** Prints highlighted fixture operation outputs to stdout. */
export function printFixtureOutputSummary(summary: FixtureOutputSummary): void {
    console.log(formatFixtureOutputSummary(summary))
}
