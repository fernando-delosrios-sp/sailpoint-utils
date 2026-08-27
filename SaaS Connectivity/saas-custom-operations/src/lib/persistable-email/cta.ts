import { escapeHtml } from './escape'

/**
 * Builds an unquoted href CTA: `<a href=${escapedUrl}>${escapedLabel}</a>`.
 * DelimitedFile/`provisionAsCsv`-safe when the URL has no spaces.
 */
export function renderUnquotedHrefCta(url: string, label: string): string {
    const safeUrl = escapeHtml(url)
    const safeLabel = escapeHtml(label)
    return `<a href=${safeUrl}>${safeLabel}</a>`
}
