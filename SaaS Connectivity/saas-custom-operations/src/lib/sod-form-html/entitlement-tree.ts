import { escapeHtml } from './escape'
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

function renderEntitlementLine(id: string, name: string | undefined): string {
    const displayName = name?.trim()
    const label = escapeHtml(displayName && displayName !== id ? displayName : (displayName ?? id))
    return `<li><strong>${label}</strong> ${renderTypeTag('ENTITLEMENT')}</li>`
}

function renderTreeBody(entitlementIds: string[], expanded: EntitlementTreeExpansion): string {
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

        lines.push(
            `<li><strong>${escapeHtml(profile.name)}</strong> ${renderTypeTag('ACCESS_PROFILE')}<ul>`
        )
        for (const ent of matching) {
            lines.push(renderEntitlementLine(ent.id, ent.name))
            rendered.add(ent.id)
        }
        lines.push('</ul></li>')
    }

    for (const ent of expanded.entitlements) {
        if (idSet.has(ent.id) && !rendered.has(ent.id)) {
            lines.push(renderEntitlementLine(ent.id, ent.name))
        }
    }

    return lines.join('')
}

/** Renders access-sod-remediation entitlement tree HTML with plain and outcome variants. */
export function renderEntitlementTree(
    entitlementIds: string[],
    expanded: EntitlementTreeExpansion
): SideVariants {
    const bodyHtml = renderTreeBody(entitlementIds, expanded)

    if (entitlementIds.length === 0) {
        return buildBlockSideVariants(bodyHtml)
    }

    return buildSideVariants(bodyHtml)
}
