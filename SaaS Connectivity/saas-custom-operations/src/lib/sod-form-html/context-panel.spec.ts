import { describe, expect, it } from 'vitest'
import { buildAccessModelSodContextPanelHtml, buildIdentitySodContextPanelHtml } from './context-panel'

const uiOrigin = 'https://tenant.example.com'

describe('buildIdentitySodContextPanelHtml', () => {
    const baseInput = {
        uiOrigin,
        identityId: 'ident-1',
        identityName: 'Alice Example',
        policyId: 'pol-1',
        policyName: 'AP vs AP',
        violationId: 'vio-1',
        groupAPathsHtml: '<ul><li>A</li></ul>',
        groupBPathsHtml: '<ul><li>B</li></ul>',
        hasControls: true,
    }

    it('includes What we found and What we need from you blocks', () => {
        const html = buildIdentitySodContextPanelHtml(baseInput)

        expect(html).toContain('What we found')
        expect(html).toContain('What we need from you')
        expect(html).toContain('Choose <strong>Correct</strong> or <strong>Mitigate</strong>')
    })

    it('links identity, policy, and violations list when uiOrigin is available', () => {
        const html = buildIdentitySodContextPanelHtml(baseInput)

        expect(html).toContain('/ui/a/admin/identities/ident-1/details/attributes')
        expect(html).toContain('/ui/sod/policy-management/pol-1/details')
        expect(html).toContain('vio-1')
        expect(html).toContain('/ui/sod/violations')
        expect(html).toContain('View SOD violations')
    })

    it('Violation id plain with violations list link', () => {
        const html = buildIdentitySodContextPanelHtml(baseInput)

        expect(html).toContain('<strong>Violation:</strong> vio-1 · ')
        expect(html).not.toContain('/ui/sod/violations/vio-1')
    })

    it('notes when no compensating controls exist', () => {
        const html = buildIdentitySodContextPanelHtml({ ...baseInput, hasControls: false })

        expect(html).toContain('No compensating controls are configured')
        expect(html).not.toContain('Mitigate')
    })

    it('Offline context panel omits admin links', () => {
        const html = buildIdentitySodContextPanelHtml({ ...baseInput, uiOrigin: undefined })

        expect(html).toContain('Alice Example')
        expect(html).not.toMatch(/href=/)
    })
})

describe('buildAccessModelSodContextPanelHtml', () => {
    it('links role access item and policy for role violations', () => {
        const html = buildAccessModelSodContextPanelHtml({
            uiOrigin,
            accessItemId: 'role-r',
            accessItemType: 'ROLE',
            accessItemName: 'Finance Role',
            policyId: 'policy-p',
            policyName: 'AP/AR Separation',
        })

        expect(html).toContain('/ui/a/admin/access/roles/landing-page/details/role-r')
        expect(html).toContain('/ui/sod/policy-management/policy-p/details')
        expect(html).toContain('Select which side&apos;s entitlements should be removed')
    })

    it('Access profile item links correctly', () => {
        const html = buildAccessModelSodContextPanelHtml({
            uiOrigin,
            accessItemId: 'ap-1',
            accessItemType: 'ACCESS_PROFILE',
            accessItemName: 'SAP Suite',
            policyId: 'policy-p',
            policyName: 'AP/AR Separation',
        })

        expect(html).toContain('/ui/a/admin/access/access-profiles/landing-page/details/ap-1')
    })
})
