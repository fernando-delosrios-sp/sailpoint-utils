import { buildGroupColumnLayouts, GroupColumnLayoutHtml, renderEntitlementTree } from '../../lib/sod-form-html'
import { ExpandedAccessItemEntitlements } from './expand-access-item-entitlements'

/** Builds the three side-by-side column HTML formInput values for form launch. */
export function buildGroupContentsHtml(
    groupAIds: string[],
    groupBIds: string[],
    expanded: ExpandedAccessItemEntitlements,
    uiOrigin?: string
): GroupColumnLayoutHtml {
    const groupAVariants = renderEntitlementTree(groupAIds, expanded, { uiOrigin })
    const groupBVariants = renderEntitlementTree(groupBIds, expanded, { uiOrigin })
    return buildGroupColumnLayouts(groupAVariants, groupBVariants)
}
