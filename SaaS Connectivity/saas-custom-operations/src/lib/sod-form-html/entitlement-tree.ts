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

function entitlementDisplayLabel(id: string, name: string | undefined): string {
    const displayName = name?.trim()
    return escapeHtml(displayName && displayName !== id ? displayName : (displayName ?? id))
}

function renderEntitlementLine(id: string, name: string | undefined): string {
    return `<li><strong>${entitlementDisplayLabel(id, name)}</strong> ${renderTypeTag('ENTITLEMENT')}</li>`
}

function renderOffendingEntitlementMention(matching: EntitlementRef[]): string {
    const labels = matching
        .map((ent) => `<strong>${entitlementDisplayLabel(ent.id, ent.name)}</strong>`)
        .join(', ')
    return ` — offending: ${labels} ${renderTypeTag('ENTITLEMENT')}`
}

function renderFlatAccessProfileLine(profile: NestedAccessProfileBundle, matching: EntitlementRef[]): string {
    return `<li><strong>${escapeHtml(profile.name)}</strong> ${renderTypeTag('ACCESS_PROFILE')}${renderOffendingEntitlementMention(matching)}</li>`
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

        lines.push(renderFlatAccessProfileLine(profile, matching))
        for (const ent of matching) {
            rendered.add(ent.id)
        }
    }

    for (const ent of expanded.entitlements) {
        if (idSet.has(ent.id) && !rendered.has(ent.id)) {
            lines.push(renderEntitlementLine(ent.id, ent.name))
        }
    }

    return lines.join('')
}

/** Renders access-model-sod-remediation group column HTML with flat access profile lines and outcome variants. */
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
