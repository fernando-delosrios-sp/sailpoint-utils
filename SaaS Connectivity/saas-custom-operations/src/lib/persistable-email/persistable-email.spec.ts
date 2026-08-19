import { describe, expect, it } from 'vitest'
import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import {
    escapeHtml,
    fitPersistableHtml,
    renderUnquotedHrefCta,
    truncateWithEllipsis,
} from './index'

describe('persistable-email escapeHtml', () => {
    it('HTML escape: replaces &, <, >, and " with entities', () => {
        expect(escapeHtml('A & B <script>"x"</script>')).toBe(
            'A &amp; B &lt;script&gt;&quot;x&quot;&lt;/script&gt;'
        )
    })
})

describe('persistable-email truncateWithEllipsis', () => {
    it('Truncate escaped text with ellipsis: caps length and ends with … when truncated', () => {
        const escaped = 'ABCDEFGHIJ'
        const result = truncateWithEllipsis(escaped, 5)
        expect(result.length).toBeLessThanOrEqual(5)
        expect(result).toBe('ABCD…')
        expect(result.endsWith('…')).toBe(true)
    })

    it('returns the original string when within max length', () => {
        expect(truncateWithEllipsis('short', 10)).toBe('short')
    })
})

describe('persistable-email renderUnquotedHrefCta', () => {
    it('Unquoted href CTA: escapes href and label without quoting href', () => {
        const html = renderUnquotedHrefCta('https://tenant.example/form?a=1&b=2', 'Open <here>')
        expect(html).toBe(
            '<a href=https://tenant.example/form?a=1&amp;b=2>Open &lt;here&gt;</a>'
        )
        expect(html).not.toMatch(/href="/)
    })
})

describe('persistable-email fitPersistableHtml', () => {
    it('Fit within STRING max length: shortens name slots and preserves CTA', () => {
        const cta = renderUnquotedHrefCta('https://tenant.example/form/1', 'Remediate here')
        const longA = escapeHtml('A'.repeat(200))
        const longB = escapeHtml('B'.repeat(200))

        const html = fitPersistableHtml({
            slots: { item: longA, policy: longB },
            render: (s) =>
                `<p>Please review ${s.item} for policy ${s.policy}. ${cta}.</p>`,
            maxLength: ISC_STRING_ATTRIBUTE_MAX_LENGTH,
        })

        expect(html.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(html).toContain(cta)
        expect(html).toContain('<a href=https://tenant.example/form/1>Remediate here</a>')
    })

    it('Optional suffix dropped when over budget', () => {
        const cta = renderUnquotedHrefCta('https://tenant.example/form/1', 'Remediate here')
        const identity = escapeHtml('Identity Name')
        const policy = escapeHtml('Policy Name')
        const controlsNote = ' No compensating controls are available.'

        const html = fitPersistableHtml({
            slots: { identity, policy },
            optionalSuffixes: {
                controls: controlsNote,
            },
            render: (s, suffixes) =>
                `<p>Please review a SOD violation for ${s.identity} (${s.policy}). paths.${suffixes.controls ?? ''} ${cta}.</p>`,
            maxLength: 120,
        })

        expect(html.length).toBeLessThanOrEqual(120)
        expect(html).not.toContain('compensating controls')
        expect(html).toContain(cta)
    })

    it('keeps optional suffix when the full render fits', () => {
        const cta = renderUnquotedHrefCta('https://t.example/f', 'Go')
        const html = fitPersistableHtml({
            slots: { name: escapeHtml('Pat') },
            optionalSuffixes: { note: ' Extra note.' },
            render: (s, suffixes) => `<p>${s.name}.${suffixes.note ?? ''} ${cta}</p>`,
            maxLength: ISC_STRING_ATTRIBUTE_MAX_LENGTH,
        })

        expect(html).toContain('Extra note.')
        expect(html).toContain(cta)
    })

    it('No ISC side effects: helpers are pure string transforms', () => {
        // Pure functions — no SDK / Forms clients are imported or invoked by this module.
        expect(typeof escapeHtml('x')).toBe('string')
        expect(typeof truncateWithEllipsis('xy', 1)).toBe('string')
        expect(typeof renderUnquotedHrefCta('https://x', 'y')).toBe('string')
        expect(
            typeof fitPersistableHtml({
                slots: { a: 'a' },
                render: (s) => `<p>${s.a}</p>`,
            })
        ).toBe('string')
    })
})
