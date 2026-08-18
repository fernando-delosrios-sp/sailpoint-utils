/** Renders group A and group B HTML side by side for a single DESCRIPTION swap. */
export function renderSideBySideColumns(groupAHtml: string, groupBHtml: string): string {
    return `<div style='display:flex; gap:24px; align-items:flex-start;'><div style='flex:1; min-width:0;'><p style='margin:0 0 8px; font-weight:600;'>Group A</p>${groupAHtml}</div><div style='flex:1; min-width:0;'><p style='margin:0 0 8px; font-weight:600;'>Group B</p>${groupBHtml}</div></div>`
}

export interface GroupColumnLayoutHtml {
    groupColumnsHtmlPlain: string
    groupColumnsHtmlWhenGroupARemoved: string
    groupColumnsHtmlWhenGroupBRemoved: string
}

/** Builds three side-by-side column layouts for plain and remediation-side selection states. */
export function buildGroupColumnLayouts(
    groupA: { plain: string; asKept: string; asRemoved: string },
    groupB: { plain: string; asKept: string; asRemoved: string }
): GroupColumnLayoutHtml {
    return {
        groupColumnsHtmlPlain: renderSideBySideColumns(groupA.plain, groupB.plain),
        groupColumnsHtmlWhenGroupARemoved: renderSideBySideColumns(groupA.asRemoved, groupB.asKept),
        groupColumnsHtmlWhenGroupBRemoved: renderSideBySideColumns(groupA.asKept, groupB.asRemoved),
    }
}
