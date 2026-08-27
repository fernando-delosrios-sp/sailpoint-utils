import { describe, expect, it } from 'vitest'
import { renderIscUiLink, resolveUiOrigin } from './isc-ui-links'

describe('resolveUiOrigin', () => {
    it('Standard api hostname maps to UI origin', () => {
        expect(resolveUiOrigin('https://tenant.api.identitynow.com')).toBe('https://tenant.identitynow.com')
    })

    it('returns hostname as-is when no api segment is present', () => {
        expect(resolveUiOrigin('https://tenant.example.com')).toBe('https://tenant.example.com')
    })

    it('returns undefined for blank apiUrl', () => {
        expect(resolveUiOrigin('')).toBeUndefined()
        expect(resolveUiOrigin('   ')).toBeUndefined()
    })
})

describe('renderIscUiLink', () => {
    const uiOrigin = 'https://tenant.example.com'

    it('Identity admin link', () => {
        const html = renderIscUiLink(uiOrigin, 'identity', 'Alice Example', 'ident-1')

        expect(html).toBe(
            '<a href="https://tenant.example.com/ui/a/admin/identities/ident-1/details/attributes" target="_blank" rel="noopener noreferrer">Alice Example</a>'
        )
    })

    it('SoD policy admin link', () => {
        const html = renderIscUiLink(uiOrigin, 'sodPolicy', 'AP vs AR', 'pol-1')

        expect(html).toContain('/ui/sod/policy-management/pol-1/details')
    })

    it('Role access admin link', () => {
        const html = renderIscUiLink(uiOrigin, 'role', 'Finance Role', 'role-1')

        expect(html).toContain('/ui/a/admin/access/roles/landing-page/details/role-1')
    })

    it('Access profile admin link', () => {
        const html = renderIscUiLink(uiOrigin, 'accessProfile', 'SAP Suite', 'ap-1')

        expect(html).toContain('/ui/a/admin/access/access-profiles/landing-page/details/ap-1')
    })

    it('Entitlement admin link', () => {
        const html = renderIscUiLink(uiOrigin, 'entitlement', 'Accounts Payable', 'ent-1')

        expect(html).toContain('/ui/a/admin/access/entitlements/landing-page/details/ent-1')
    })

    it('Violations list link', () => {
        const html = renderIscUiLink(uiOrigin, 'violationList', 'View SOD violations')

        expect(html).toBe(
            '<a href="https://tenant.example.com/ui/sod/violations" target="_blank" rel="noopener noreferrer">View SOD violations</a>'
        )
    })

    it('Offline omits UI origin and renders plain escaped label', () => {
        const html = renderIscUiLink(undefined, 'identity', 'Alice & Bob', 'ident-1')

        expect(html).toBe('Alice &amp; Bob')
        expect(html).not.toContain('<a href=')
    })

    it('HTML-escapes link labels', () => {
        const html = renderIscUiLink(uiOrigin, 'identity', 'Alice <script>"x"</script>', 'ident-1')

        expect(html).toContain('Alice &lt;script&gt;&quot;x&quot;&lt;/script&gt;')
        expect(html).not.toContain('<script>')
    })

    it('URL-encodes id path segments', () => {
        const html = renderIscUiLink(uiOrigin, 'identity', 'Alice', 'id/with/slash')

        expect(html).toContain('/identities/id%2Fwith%2Fslash/details/attributes')
    })
})
