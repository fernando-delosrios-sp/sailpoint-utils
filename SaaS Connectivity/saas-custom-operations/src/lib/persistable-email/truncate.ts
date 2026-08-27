/** Truncates an already-escaped string, appending … when shortened. */
export function truncateWithEllipsis(text: string, maxLength: number): string {
    if (text.length <= maxLength) {
        return text
    }

    if (maxLength <= 1) {
        return text.slice(0, maxLength)
    }

    return `${text.slice(0, maxLength - 1)}…`
}
