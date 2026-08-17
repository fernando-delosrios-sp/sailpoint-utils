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

    it('renders entitlement names instead of raw ids', () => {
        const html = buildGroupContentsHtml(['ent-a'], ['ent-c'], expanded)

        expect(html.groupAContentsHtml).toContain('Accounts Receivable')
        expect(html.groupAContentsHtml).not.toContain('6684f7f2')
        expect(html.groupBContentsHtml).toContain('Accounts Payable')
        expect(html.groupBContentsHtml).toContain('SAP Suite')
    })

    it('applies distinct side colors to group column html', () => {
        const html = buildGroupContentsHtml(['ent-a'], ['ent-c'], expanded)

        expect(html.groupAContentsHtml).toContain('color:#1565c0')
        expect(html.groupAContentsHtml).toContain('background-color:#e3f2fd')
        expect(html.groupBContentsHtml).toContain('color:#7b1fa2')
        expect(html.groupBContentsHtml).toContain('background-color:#f3e5f5')
    })

    it('falls back to id when name is unavailable', () => {
        const html = buildGroupContentsHtml(['ent-unknown'], [], {
            entitlementIds: new Set(['ent-unknown']),
            entitlements: [{ id: 'ent-unknown' }],
            nestedProfiles: [],
        })

        expect(html.groupAContentsHtml).toContain('ent-unknown')
    })
})
