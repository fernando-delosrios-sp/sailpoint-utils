import { renderIscUiLink } from './isc-ui-links'
import { buildBlockSideVariants, buildSideVariants, SideVariants } from './outcome-panel'
import { renderTypeTag } from './type-tag'

export interface EntitlementRef {
    id: string
    name?: string
}

export interface NestedAccessProfileBundle {
    id: string
    name: string
    entitlements: EntitlementRef[]
}

export interface EntitlementTreeExpansion {
    entitlements: EntitlementRef[]
    nestedProfiles: NestedAccessProfileBundle[]
}

export interface RenderEntitlementTreeOptions {
    uiOrigin?: string
}

function entitlementDisplayLabel(id: string, name: string | undefined, uiOrigin?: string): string {
    const displayName = name?.trim()
    const label = displayName && displayName !== id ? displayName : (displayName ?? id)
    return renderIscUiLink(uiOrigin, 'entitlement', label, id)
}

function renderEntitlementLine(id: string, name: string | undefined, uiOrigin?: string): string {
    return `<li><strong>${entitlementDisplayLabel(id, name, uiOrigin)}</strong> ${renderTypeTag('ENTITLEMENT')}</li>`
}

function renderContainedEntitlementsList(matching: EntitlementRef[], uiOrigin?: string): string {
    const items = matching
        .map(
            (ent) =>
                `<li><strong>${entitlementDisplayLabel(ent.id, ent.name, uiOrigin)}</strong> ${renderTypeTag('ENTITLEMENT')}</li>`
        )
        .join('')
    return ` — Contains:<ul style='margin:4px 0 0; padding-left:20px;'>${items}</ul>`
}

function renderFlatAccessProfileLine(
    profile: NestedAccessProfileBundle,
    matching: EntitlementRef[],
    uiOrigin?: string
): string {
    const profileLabel = renderIscUiLink(uiOrigin, 'accessProfile', profile.name, profile.id)
    return `<li><strong>${profileLabel}</strong> ${renderTypeTag('ACCESS_PROFILE')}${renderContainedEntitlementsList(matching, uiOrigin)}</li>`
}

function renderTreeBody(
    entitlementIds: string[],
    expanded: EntitlementTreeExpansion,
    uiOrigin?: string
): string {
    if (entitlementIds.length === 0) {
        return '<p><em>No matching entitlements on this side.</em></p>'
    }

    const idSet = new Set(entitlementIds)
    const lines: string[] = []
    const rendered = new Set<string>()

    for (const profile of expanded.nestedProfiles) {
        const matching = profile.entitlements.filter((ent) => idSet.has(ent.id))
        if (matching.length === 0) {
            continue
        }

        lines.push(renderFlatAccessProfileLine(profile, matching, uiOrigin))
        for (const ent of matching) {
            rendered.add(ent.id)
        }
    }

    for (const ent of expanded.entitlements) {
        if (idSet.has(ent.id) && !rendered.has(ent.id)) {
            lines.push(renderEntitlementLine(ent.id, ent.name, uiOrigin))
        }
    }

    return lines.join('')
}

/** Renders access-model-sod-remediation group column HTML with access profile lines and outcome variants. */
export function renderEntitlementTree(
    entitlementIds: string[],
    expanded: EntitlementTreeExpansion,
    options: RenderEntitlementTreeOptions = {}
): SideVariants {
    const bodyHtml = renderTreeBody(entitlementIds, expanded, options.uiOrigin)

    if (entitlementIds.length === 0) {
        return buildBlockSideVariants(bodyHtml)
    }

    return buildSideVariants(bodyHtml)
}
