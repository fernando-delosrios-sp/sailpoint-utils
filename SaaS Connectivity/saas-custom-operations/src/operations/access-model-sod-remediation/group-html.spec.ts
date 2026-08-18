import { describe, expect, it } from 'vitest'
import { buildGroupContentsHtml } from './group-html'
import { ExpandedAccessItemEntitlements } from './expand-access-item-entitlements'

describe('buildGroupContentsHtml', () => {
    const expanded: ExpandedAccessItemEntitlements = {
        entitlementIds: new Set(['ent-a', 'ent-c']),
        entitlements: [
            { id: 'ent-a', name: 'Accounts Receivable' },
            { id: 'ent-c', name: 'Accounts Payable' },
        ],
        nestedProfiles: [
            {
                id: 'ap-1',
                name: 'SAP Suite',
                entitlements: [{ id: 'ent-c', name: 'Accounts Payable' }],
            },
        ],
    }

    it('builds composite side-by-side column layouts for each remediation selection state', () => {
        const html = buildGroupContentsHtml(['ent-a'], ['ent-c'], expanded)

        expect(html.groupColumnsHtmlPlain).toContain('Group A')
        expect(html.groupColumnsHtmlPlain).toContain('Group B')
        expect(html.groupColumnsHtmlPlain).toContain('Accounts Receivable')
        expect(html.groupColumnsHtmlPlain).toContain('Accounts Payable')
        expect(html.groupColumnsHtmlPlain).toContain('— offending:')
        expect(html.groupColumnsHtmlPlain).toContain('SAP Suite')
        expect(html.groupColumnsHtmlPlain).not.toMatch(/SAP Suite[\s\S]*<ul>/)
        expect(html.groupColumnsHtmlPlain).not.toContain('#e8f5e9')
        expect(html.groupColumnsHtmlPlain).not.toContain('#ffebee')

        expect(html.groupColumnsHtmlWhenGroupARemoved).toContain('#ffebee')
        expect(html.groupColumnsHtmlWhenGroupARemoved).toContain('#e8f5e9')
        expect(html.groupColumnsHtmlWhenGroupBRemoved).toContain('#e8f5e9')
        expect(html.groupColumnsHtmlWhenGroupBRemoved).toContain('#ffebee')
    })

    it('falls back to id when name is unavailable', () => {
        const html = buildGroupContentsHtml(['ent-unknown'], [], {
            entitlementIds: new Set(['ent-unknown']),
            entitlements: [{ id: 'ent-unknown' }],
            nestedProfiles: [],
        })

        expect(html.groupColumnsHtmlPlain).toContain('ent-unknown')
    })
})
