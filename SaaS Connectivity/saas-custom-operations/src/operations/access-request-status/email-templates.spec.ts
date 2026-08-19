import { describe, expect, it } from 'vitest'
import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { resolveUiOrigin } from '../../lib/sod-form-html'
import type { AccessRequestAnalytics } from './compute-analytics'
import { buildApprovalEmailBody } from './email-templates'

const analytics = {
    iscRiskName: 'Critical',
    xdrScore: '1.00%',
    sodPrediction: 'N/A',
    violatedPolicyNames: 'N/A',
    recommendationsDecision: 'YES',
    recommendationsInterpretations: 'ok',
    accessRequestStatus: {},
    xdrData: null,
} as unknown as AccessRequestAnalytics

const context = {
    managerRefName: 'Manager Name',
    displayName: 'Jane Doe',
    requestedItemName: 'Test Role',
}

describe('buildApprovalEmailBody', () => {
    it('links to the invoking tenant Approval Center', () => {
        const body = buildApprovalEmailBody(analytics, {
            ...context,
            uiOrigin: resolveUiOrigin('https://company22986-poc.api.identitynow.com'),
        })

        expect(body).toContain(
            '<a href=https://company22986-poc.identitynow.com/ui/d/approvals/requested-items>ISC Approval Center</a>'
        )
        expect(body).not.toContain('identitynow-demo.com')
    })

    it('renders the Approval Center as plain text when no tenant origin resolves', () => {
        const body = buildApprovalEmailBody(analytics, { ...context, uiOrigin: undefined })

        expect(body).toContain('Review in ISC Approval Center.')
        expect(body).not.toContain('<a href')
    })

    it('fits ISC STRING storage without truncation', () => {
        const body = buildApprovalEmailBody(analytics, {
            ...context,
            uiOrigin: resolveUiOrigin('https://company22986-poc.api.identitynow.com'),
        })

        expect(body.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(body).toContain('Manager Name, Jane Doe requested Test Role (Critical risk).')
        expect(body.endsWith('</p>')).toBe(true)
    })

    it('shortens long names instead of overflowing the attribute limit', () => {
        const body = buildApprovalEmailBody(analytics, {
            managerRefName: 'M'.repeat(120),
            displayName: 'I'.repeat(120),
            requestedItemName: 'R'.repeat(120),
            uiOrigin: resolveUiOrigin('https://company22986-poc.api.identitynow.com'),
        })

        expect(body.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(body).toContain('…')
        expect(body).toContain('/ui/d/approvals/requested-items')
    })

    it('escapes user-controlled names', () => {
        const body = buildApprovalEmailBody(analytics, {
            ...context,
            requestedItemName: '<script>"x"</script>',
            uiOrigin: resolveUiOrigin('https://company22986-poc.api.identitynow.com'),
        })

        expect(body).not.toContain('<script>')
        expect(body).toContain('&lt;script&gt;&quot;x&quot;&lt;/script&gt;')
    })
})
