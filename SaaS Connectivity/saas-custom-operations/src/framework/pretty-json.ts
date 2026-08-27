const INDENT = 4

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
