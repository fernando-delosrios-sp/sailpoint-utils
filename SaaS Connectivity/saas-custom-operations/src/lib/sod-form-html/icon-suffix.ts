/** Formats zero or more emoji markers as a space-separated suffix. */
export function iconSuffix(...icons: string[]): string {
    const filtered = icons.filter((icon) => icon.length > 0)
    return filtered.length === 0 ? '' : ` ${filtered.join(' ')}`
}
