import { buildGroupColumnLayouts, GroupColumnLayoutHtml, renderEntitlementTree } from '../../lib/sod-form-html'
import { ExpandedAccessItemEntitlements } from './expand-access-item-entitlements'

/** Builds the three side-by-side column HTML formInput values for form launch. */
export function buildGroupContentsHtml(
    groupAIds: string[],
    groupBIds: string[],
    expanded: ExpandedAccessItemEntitlements
): GroupColumnLayoutHtml {
    const groupAVariants = renderEntitlementTree(groupAIds, expanded)
    const groupBVariants = renderEntitlementTree(groupBIds, expanded)
    return buildGroupColumnLayouts(groupAVariants, groupBVariants)
}
