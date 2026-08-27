import { describe, expect, it } from 'vitest'
import { buildGroupColumnLayouts, renderSideBySideColumns } from './column-layout'

describe('column-layout', () => {
    const groupA = {
        plain: '<ul><li>A plain</li></ul>',
        asKept: '<ul style="background:#e8f5e9">A kept</ul>',
        asRemoved: '<ul style="background:#ffebee">A removed</ul>',
    }
    const groupB = {
        plain: '<ul><li>B plain</li></ul>',
        asKept: '<ul style="background:#e8f5e9">B kept</ul>',
        asRemoved: '<ul style="background:#ffebee">B removed</ul>',
    }

    it('renderSideBySideColumns places group labels and content in a flex row', () => {
        const html = renderSideBySideColumns(groupA.plain, groupB.plain)

        expect(html).toContain("display:flex")
        expect(html).toContain('Group A')
        expect(html).toContain('Group B')
        expect(html).toContain('A plain')
        expect(html).toContain('B plain')
        expect(html).toContain('margin-bottom:24px')
    })

    it('buildGroupColumnLayouts maps kept/removed variants per remediation side', () => {
        const layouts = buildGroupColumnLayouts(groupA, groupB)

        expect(layouts.groupColumnsHtmlPlain).toContain('A plain')
        expect(layouts.groupColumnsHtmlPlain).toContain('B plain')
        expect(layouts.groupColumnsHtmlWhenGroupARemoved).toContain('A removed')
        expect(layouts.groupColumnsHtmlWhenGroupARemoved).toContain('B kept')
        expect(layouts.groupColumnsHtmlWhenGroupBRemoved).toContain('A kept')
        expect(layouts.groupColumnsHtmlWhenGroupBRemoved).toContain('B removed')
    })
})
