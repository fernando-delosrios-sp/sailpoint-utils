import { describe, expect, it } from 'vitest'
import {
    buildSideVariants,
    escapeHtml,
    iconSuffix,
    renderEmojiLegend,
    renderEntitlementTree,
    renderFlatAccessPathList,
    renderTypeTag,
    wrapOutcomePanel,
} from './index'

describe('sod-form-html escapeHtml', () => {
    it('escapes HTML special characters', () => {
        expect(escapeHtml('A & B <script>"x"</script>')).toBe('A &amp; B &lt;script&gt;&quot;x&quot;&lt;/script&gt;')
    })
})

describe('sod-form-html renderTypeTag', () => {
    it('renders pill-style type tags for role, access profile, and entitlement', () => {
        expect(renderTypeTag('ROLE')).toContain('role')
        expect(renderTypeTag('ACCESS_PROFILE')).toContain('access profile')
        expect(renderTypeTag('ENTITLEMENT')).toContain('entitlement')
        expect(renderTypeTag('ROLE')).toContain('border-radius:4px')
    })

    it('does not prefix display names with Role: or Access Profile:', () => {
        const tag = renderTypeTag('ROLE')
        expect(tag).not.toMatch(/^Role:/)
        expect(tag).not.toContain('Role:')
    })
})

describe('sod-form-html iconSuffix', () => {
    it('formats multiple emoji markers space-separated', () => {
        expect(iconSuffix('⭐', '✅')).toBe(' ⭐ ✅')
    })

    it('returns empty string when no icons provided', () => {
        expect(iconSuffix()).toBe('')
    })
})

describe('sod-form-html wrapOutcomePanel', () => {
    it('uses green background for keep outcome', () => {
        const html = wrapOutcomePanel('<li>item</li>', 'keep')
        expect(html).toContain('#e8f5e9')
        expect(html).toContain('#2e7d32')
        expect(html).toContain('border-left:4px solid')
    })

    it('uses red background for remove outcome', () => {
        const html = wrapOutcomePanel('<li>item</li>', 'remove')
        expect(html).toContain('#ffebee')
        expect(html).toContain('#c62828')
    })
})

describe('sod-form-html buildSideVariants', () => {
    it('returns plain with neutral shell aligned to outcome panels', () => {
        const variants = buildSideVariants('<li>Ent A</li>')

        expect(variants.plain).toContain('padding:8px 12px 8px 20px')
        expect(variants.plain).toContain('border-left:4px solid transparent')
        expect(variants.plain).not.toContain('#e8f5e9')
        expect(variants.plain).not.toContain('#ffebee')
        expect(variants.asKept).toContain('#e8f5e9')
        expect(variants.asRemoved).toContain('#ffebee')
        expect(variants.asKept).toContain('padding:8px 12px 8px 20px')
        expect(variants.asKept).toContain('<li>Ent A</li>')
        expect(variants.asRemoved).toContain('<li>Ent A</li>')
    })
})

describe('sod-form-html renderEmojiLegend', () => {
    it('decodes revocability, keep, and privileged icons', () => {
        const legend = renderEmojiLegend()

        expect(legend).toContain('privileged')
        expect(legend).toContain('recommended to keep')
        expect(legend).toContain('revocable')
        expect(legend).toContain('not directly revocable')
        expect(legend).toContain('🔐')
        expect(legend).toContain('⭐')
        expect(legend).toContain('✅')
        expect(legend).toContain('🚫')
    })
})

describe('sod-form-html renderFlatAccessPathList', () => {
    it('renders icon-only suffixes in privileged keep revocable order', () => {
        const variants = renderFlatAccessPathList([
            {
                type: 'ENTITLEMENT',
                name: 'Ent A',
                revocable: true,
                privileged: true,
                keepRecommendation: 'YES',
            },
        ])

        expect(variants.plain).toContain('🔐 ⭐ ✅')
        expect(variants.plain).not.toContain('Revocable')
        expect(variants.plain).not.toContain('Recommended to keep')
        expect(variants.plain).toContain('entitlement')
    })

    it('nests grantor-granted entitlements under role or access profile Contains lists', () => {
        const variants = renderFlatAccessPathList([
            {
                id: 'ent-1',
                type: 'ENTITLEMENT',
                name: 'AccountingGeneral',
                revocable: false,
                reason: 'granted-via-access-profile',
                grantedVia: { type: 'ACCESS_PROFILE', id: 'ap-1', name: 'T2.01 Accounting General' },
            },
            {
                id: 'ap-1',
                type: 'ACCESS_PROFILE',
                name: 'T2.01 Accounting General',
                revocable: true,
            },
        ])

        expect(variants.plain).toContain('T2.01 Accounting General')
        expect(variants.plain).toContain('AccountingGeneral')
        expect(variants.plain).toContain('— Contains:')
        expect(variants.plain).toMatch(/T2\.01 Accounting General[\s\S]*<ul[\s\S]*AccountingGeneral/)
        expect(variants.plain).not.toContain('(via T2.01 Accounting General access profile)')
        expect(variants.asRemoved).not.toContain('(via T2.01 Accounting General access profile)')
        expect(variants.plain).toContain('🚫')
        expect(variants.plain).toContain('✅')
    })

    it('includes granted-via phrase on standalone non-revocable lines without a same-side grantor', () => {
        const variants = renderFlatAccessPathList([
            {
                type: 'ENTITLEMENT',
                name: 'Ent B',
                revocable: false,
                grantedVia: { type: 'ROLE', name: 'Finance Role' },
            },
        ])

        expect(variants.plain).toContain('🚫')
        expect(variants.plain).toContain('<em>(via Finance Role role)</em>')
    })

    it('links grantor reference in granted-via phrase when uiOrigin and grantor id are present', () => {
        const uiOrigin = 'https://tenant.example.com'
        const variants = renderFlatAccessPathList(
            [
                {
                    type: 'ENTITLEMENT',
                    name: 'Ent B',
                    revocable: false,
                    grantedVia: { type: 'ROLE', id: 'role-1', name: 'Finance Role' },
                },
            ],
            { uiOrigin }
        )

        expect(variants.plain).toContain('/ui/a/admin/access/roles/landing-page/details/role-1')
        expect(variants.plain).toContain('<em>(via ')
        expect(variants.plain).toContain('Finance Role')
        expect(variants.plain).toContain(' role)</em>')
    })

    it('asRemoved uses red panels for all lines under a revocable grantor on the removed side', () => {
        const variants = renderFlatAccessPathList([
            {
                id: 'ent-1',
                type: 'ENTITLEMENT',
                name: 'AccountingGeneral',
                revocable: false,
                grantedVia: { type: 'ACCESS_PROFILE', id: 'ap-1', name: 'Finance AP' },
            },
            {
                id: 'ap-1',
                type: 'ACCESS_PROFILE',
                name: 'Finance AP',
                revocable: true,
            },
        ])

        expect(variants.asRemoved).toContain('#ffebee')
        expect(variants.asRemoved).not.toContain('#e8f5e9')
        expect(variants.asRemoved).toContain('AccountingGeneral')
        expect(variants.asRemoved).toContain('Finance AP')
        const redPanels = variants.asRemoved.match(/#ffebee/g)?.length ?? 0
        expect(redPanels).toBe(2)
    })

    it('asRemoved keeps non-revocable grantor green while revocable contained entitlements are red', () => {
        const variants = renderFlatAccessPathList([
            {
                id: 'ent-revocable',
                type: 'ENTITLEMENT',
                name: 'Nested Revocable',
                revocable: true,
                grantedVia: { type: 'ACCESS_PROFILE', id: 'ap-1', name: 'Locked AP' },
            },
            {
                id: 'ent-kept',
                type: 'ENTITLEMENT',
                name: 'Nested Not Revocable',
                revocable: false,
                grantedVia: { type: 'ACCESS_PROFILE', id: 'ap-1', name: 'Locked AP' },
            },
            {
                id: 'ap-1',
                type: 'ACCESS_PROFILE',
                name: 'Locked AP',
                revocable: false,
            },
        ])

        expect(variants.asRemoved).toContain('#ffebee')
        expect(variants.asRemoved).toContain('#e8f5e9')
        const redPanels = variants.asRemoved.match(/#ffebee/g)?.length ?? 0
        const greenPanels = variants.asRemoved.match(/#e8f5e9/g)?.length ?? 0
        expect(redPanels).toBe(1)
        expect(greenPanels).toBe(2)
    })

    it('asRemoved uses green panels for non-revocable lines and red for revocable lines', () => {
        const variants = renderFlatAccessPathList([
            {
                type: 'ENTITLEMENT',
                name: 'Ent Revocable',
                revocable: true,
            },
            {
                type: 'ENTITLEMENT',
                name: 'Ent Not Revocable',
                revocable: false,
                grantedVia: { type: 'ACCESS_PROFILE', name: 'Finance AP' },
            },
        ])

        expect(variants.asRemoved).toContain('#ffebee')
        expect(variants.asRemoved).toContain('#e8f5e9')
        expect(variants.asRemoved).toContain('Ent Revocable')
        expect(variants.asRemoved).toContain('Ent Not Revocable')
        const redPanels = variants.asRemoved.match(/#ffebee/g)?.length ?? 0
        const greenPanels = variants.asRemoved.match(/#e8f5e9/g)?.length ?? 0
        expect(redPanels).toBe(1)
        expect(greenPanels).toBe(1)
    })

    it('asRemoved with all revocable lines uses only red panels', () => {
        const variants = renderFlatAccessPathList([{ type: 'ROLE', name: 'Role A', revocable: true }])

        expect(variants.asRemoved).toContain('#ffebee')
        expect(variants.asRemoved).not.toContain('#e8f5e9')
    })

    it('prepends side hint to all variants', () => {
        const hint = '<p><em>hint</em></p>'
        const variants = renderFlatAccessPathList(
            [{ type: 'ROLE', name: 'Role A', revocable: true }],
            { sideHintHtml: hint }
        )

        expect(variants.plain.startsWith(hint)).toBe(true)
        expect(variants.asKept.startsWith(hint)).toBe(true)
        expect(variants.asRemoved.startsWith(hint)).toBe(true)
    })

    it('empty list uses outcome panels for kept and removed variants', () => {
        const variants = renderFlatAccessPathList([])

        expect(variants.plain).toContain('No access paths resolved')
        expect(variants.plain).toContain('background-color:transparent')
        expect(variants.plain).not.toContain('#e8f5e9')
        expect(variants.asKept).toContain('#e8f5e9')
        expect(variants.asRemoved).toContain('#ffebee')
        expect(variants.asKept).toContain('No access paths resolved')
        expect(variants.asRemoved).toContain('No access paths resolved')
    })

    it('empty list with side hint prepends hint to outcome variants', () => {
        const hint = '<p><em>hint</em></p>'
        const variants = renderFlatAccessPathList([], { sideHintHtml: hint })

        expect(variants.asKept.startsWith(hint)).toBe(true)
        expect(variants.asRemoved.startsWith(hint)).toBe(true)
        expect(variants.asKept).toContain('#e8f5e9')
        expect(variants.asRemoved).toContain('#ffebee')
    })

    it('Linked flat access path line', () => {
        const uiOrigin = 'https://tenant.example.com'
        const variants = renderFlatAccessPathList(
            [
                {
                    id: 'ent-a',
                    type: 'ENTITLEMENT',
                    name: 'Ent A',
                    revocable: true,
                },
            ],
            { uiOrigin }
        )

        expect(variants.plain).toContain('/ui/a/admin/access/entitlements/landing-page/details/ent-a')
        expect(variants.plain).toContain('entitlement')
        expect(variants.plain).toContain('>Ent A</a></strong>')
        expect(variants.plain).toContain('target="_blank"')
    })

    it('Offline flat access path line omits admin links', () => {
        const variants = renderFlatAccessPathList([
            {
                id: 'ent-a',
                type: 'ENTITLEMENT',
                name: 'Ent A',
                revocable: true,
            },
        ])

        expect(variants.plain).toContain('Ent A')
        expect(variants.plain).not.toMatch(/href=/)
    })
})

describe('sod-form-html renderEntitlementTree', () => {
    const expanded = {
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

    it('renders access profile lines with Contains list of side-matching entitlements', () => {
        const variants = renderEntitlementTree(['ent-a', 'ent-c'], expanded)

        expect(variants.plain).toContain('Accounts Receivable')
        expect(variants.plain).toContain('SAP Suite')
        expect(variants.plain).toContain('access profile')
        expect(variants.plain).toContain('entitlement')
        expect(variants.plain).toContain('— Contains:')
        expect(variants.plain).toContain('Accounts Payable')
        expect(variants.plain).toMatch(/SAP Suite[\s\S]*<ul[\s\S]*Accounts Payable/)
    })

    it('lists multiple side-matching entitlements under one access profile', () => {
        const multiExpanded = {
            entitlements: [{ id: 'ent-1', name: 'Ent One' }, { id: 'ent-2', name: 'Ent Two' }],
            nestedProfiles: [
                {
                    id: 'ap-1',
                    name: 'Shared AP',
                    entitlements: [
                        { id: 'ent-1', name: 'Ent One' },
                        { id: 'ent-2', name: 'Ent Two' },
                    ],
                },
            ],
        }
        const variants = renderEntitlementTree(['ent-1', 'ent-2'], multiExpanded)

        expect(variants.plain).toContain('Shared AP')
        expect(variants.plain).toContain('Ent One')
        expect(variants.plain).toContain('Ent Two')
        expect(variants.plain).toMatch(/Shared AP[\s\S]*<ul[\s\S]*Ent One[\s\S]*Ent Two/)
        expect(variants.plain.match(/Shared AP/g)?.length).toBe(1)
    })

    it('plain variant has no side-identity colored panel backgrounds', () => {
        const variants = renderEntitlementTree(['ent-a', 'ent-c'], expanded)

        expect(variants.plain).not.toContain('border-left:4px solid #1565c0')
        expect(variants.plain).not.toContain('border-left:4px solid #7b1fa2')
    })

    it('outcome variants use green and red panels', () => {
        const variants = renderEntitlementTree(['ent-a'], expanded)

        expect(variants.asKept).toContain('#e8f5e9')
        expect(variants.asRemoved).toContain('#ffebee')
    })

    it('empty side uses outcome panels for kept and removed variants', () => {
        const variants = renderEntitlementTree([], expanded)

        expect(variants.plain).toContain('No matching entitlements on this side')
        expect(variants.plain).toContain('background-color:transparent')
        expect(variants.plain).not.toContain('#e8f5e9')
        expect(variants.asKept).toContain('#e8f5e9')
        expect(variants.asRemoved).toContain('#ffebee')
        expect(variants.asKept).toContain('No matching entitlements on this side')
        expect(variants.asRemoved).toContain('No matching entitlements on this side')
    })

    it('Linked entitlement tree line', () => {
        const uiOrigin = 'https://tenant.example.com'
        const variants = renderEntitlementTree(['ent-a'], expanded, { uiOrigin })

        expect(variants.plain).toContain('/ui/a/admin/access/entitlements/landing-page/details/ent-a')
    })

    it('Linked access profile and entitlement names when UI origin present', () => {
        const uiOrigin = 'https://tenant.example.com'
        const variants = renderEntitlementTree(['ent-c'], expanded, { uiOrigin })

        expect(variants.plain).toContain('/ui/a/admin/access/access-profiles/landing-page/details/ap-1')
        expect(variants.plain).toContain('/ui/a/admin/access/entitlements/landing-page/details/ent-c')
    })
})
