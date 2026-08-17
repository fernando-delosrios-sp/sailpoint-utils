import { ExpandedAccessItemEntitlements } from './expand-access-item-entitlements'

type GroupSide = 'groupA' | 'groupB'

const GROUP_SIDE_STYLES: Record<
    GroupSide,
    { accent: string; background: string; profile: string; empty: string }
> = {
    groupA: {
        accent: '#1565c0',
        background: '#e3f2fd',
        profile: '#0d47a1',
        empty: '#546e7a',
    },
    groupB: {
        accent: '#7b1fa2',
        background: '#f3e5f5',
        profile: '#4a148c',
        empty: '#546e7a',
    },
}

function escapeHtml(text: string): string {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
}

function renderEntitlementLine(id: string, name: string | undefined, accentColor: string): string {
    const displayName = name?.trim()
    const label = escapeHtml(displayName && displayName !== id ? displayName : (displayName ?? id))
    return `<li style="color:${accentColor};"><strong>Entitlement:</strong> ${label}</li>`
}

function renderSideHtml(
    entitlementIds: string[],
    expanded: ExpandedAccessItemEntitlements,
    side: GroupSide
): string {
    const styles = GROUP_SIDE_STYLES[side]

    if (entitlementIds.length === 0) {
        return `<p style="color:${styles.empty};"><em>No matching entitlements on this side.</em></p>`
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
            `<li style="color:${styles.profile};"><strong>${escapeHtml(profile.name)}</strong> <span style="color:${styles.accent};">(access profile)</span><ul>`
        )
        for (const ent of matching) {
            lines.push(renderEntitlementLine(ent.id, ent.name, styles.accent))
            rendered.add(ent.id)
        }
        lines.push('</ul></li>')
    }

    for (const ent of expanded.entitlements) {
        if (idSet.has(ent.id) && !rendered.has(ent.id)) {
            lines.push(renderEntitlementLine(ent.id, ent.name, styles.accent))
        }
    }

    return `<ul style="margin:0; padding:8px 12px 8px 20px; background-color:${styles.background}; border-left:4px solid ${styles.accent}; border-radius:4px;">${lines.join('')}</ul>`
}

/** Builds HTML lists for group A and group B form columns. */
export function buildGroupContentsHtml(
    groupAIds: string[],
    groupBIds: string[],
    expanded: ExpandedAccessItemEntitlements
): { groupAContentsHtml: string; groupBContentsHtml: string } {
    return {
        groupAContentsHtml: renderSideHtml(groupAIds, expanded, 'groupA'),
        groupBContentsHtml: renderSideHtml(groupBIds, expanded, 'groupB'),
    }
}
