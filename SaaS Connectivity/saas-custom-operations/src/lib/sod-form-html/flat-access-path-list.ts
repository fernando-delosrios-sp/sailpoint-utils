import { escapeHtml } from './escape'
import { iconSuffix } from './icon-suffix'
import { accessKindToLinkKind, renderIscUiLink } from './isc-ui-links'
import { buildBlockSideVariants, buildSideVariants, SideVariants, wrapOutcomePanel, type OutcomeKind } from './outcome-panel'
import { renderTypeTag, AccessKind } from './type-tag'
import { REVOCABILITY_EMOJI } from './tokens'

export interface FlatAccessPathLine {
    id?: string
    type: AccessKind
    name: string
    revocable: boolean
    keepRecommendation?: 'YES' | 'MAYBE' | 'NO' | 'NOT_FOUND'
    privileged?: boolean
    grantedVia?: { type: 'ROLE' | 'ACCESS_PROFILE'; id?: string; name: string }
    reason?: 'direct-assignment' | 'granted-via-role' | 'granted-via-access-profile'
}

export interface RenderFlatAccessPathListOptions {
    /** Optional HTML prefix (e.g. side correction hint) prepended to all variants. */
    sideHintHtml?: string
    /** Tenant UI origin for ISC admin links on entity display names. */
    uiOrigin?: string
}

type GroupedAccessPathEntry =
    | { kind: 'standalone'; line: FlatAccessPathLine }
    | { kind: 'grantor'; grantor: FlatAccessPathLine; contained: FlatAccessPathLine[] }

function reasonPhrase(line: FlatAccessPathLine, uiOrigin?: string): string {
    if (line.grantedVia) {
        const kind = line.grantedVia.type === 'ROLE' ? 'role' : 'access profile'
        const grantorLabel = renderIscUiLink(
            uiOrigin,
            accessKindToLinkKind(line.grantedVia.type),
            line.grantedVia.name,
            line.grantedVia.id
        )
        return `(via ${grantorLabel} ${kind})`
    }

    switch (line.reason) {
        case 'granted-via-role':
            return '(via role)'
        case 'granted-via-access-profile':
            return '(via access profile)'
        default:
            return ''
    }
}

function renderLineIcons(line: FlatAccessPathLine): string {
    const icons: string[] = []
    if (line.privileged === true) {
        icons.push(REVOCABILITY_EMOJI.privileged)
    }
    if (line.keepRecommendation === 'YES') {
        icons.push(REVOCABILITY_EMOJI.keepRecommended)
    }
    icons.push(line.revocable ? REVOCABILITY_EMOJI.revocable : REVOCABILITY_EMOJI.notRevocable)
    return iconSuffix(...icons)
}

function renderLinkedName(line: FlatAccessPathLine, uiOrigin?: string): string {
    const label = renderIscUiLink(uiOrigin, accessKindToLinkKind(line.type), line.name, line.id)
    return `<strong>${label}</strong>`
}

function renderLineContent(line: FlatAccessPathLine, nested: boolean, uiOrigin?: string): string {
    const namePart = `${renderLinkedName(line, uiOrigin)} ${renderTypeTag(line.type)}`
    const icons = renderLineIcons(line)

    if (line.revocable || nested) {
        return `${namePart}${icons}`
    }

    const reason = reasonPhrase(line, uiOrigin)
    const reasonHtml = reason ? ` <em>${reason}</em>` : ''
    return `${namePart}${icons}${reasonHtml}`
}

function renderLineHtml(line: FlatAccessPathLine, nested: boolean, uiOrigin?: string): string {
    return `<li>${renderLineContent(line, nested, uiOrigin)}</li>`
}

function renderStandaloneLineHtml(line: FlatAccessPathLine, uiOrigin?: string): string {
    return renderLineHtml(line, false, uiOrigin)
}

function renderContainedEntitlementsList(contained: FlatAccessPathLine[], uiOrigin?: string): string {
    const items = contained.map((line) => renderLineHtml(line, true, uiOrigin)).join('')
    return ` — Contains:<ul style='margin:4px 0 0; padding-left:20px;'>${items}</ul>`
}

function renderGrantorLineHtml(
    grantor: FlatAccessPathLine,
    contained: FlatAccessPathLine[],
    uiOrigin?: string
): string {
    return `<li>${renderLineContent(grantor, false, uiOrigin)}${renderContainedEntitlementsList(contained, uiOrigin)}</li>`
}

/** Groups grantor-nested entitlements under role or access profile lines when the grantor is on the same side. */
export function groupAccessPathLines(lines: FlatAccessPathLine[]): GroupedAccessPathEntry[] {
    const grantors = new Map<string, FlatAccessPathLine>()
    for (const line of lines) {
        if ((line.type === 'ROLE' || line.type === 'ACCESS_PROFILE') && line.id) {
            grantors.set(line.id, line)
        }
    }

    const containedByGrantor = new Map<string, FlatAccessPathLine[]>()
    const nestedEntitlementIds = new Set<string>()

    for (const line of lines) {
        if (line.type !== 'ENTITLEMENT') {
            continue
        }
        const grantorId = line.grantedVia?.id
        if (!grantorId || !grantors.has(grantorId)) {
            continue
        }
        const contained = containedByGrantor.get(grantorId) ?? []
        contained.push(line)
        containedByGrantor.set(grantorId, contained)
        if (line.id) {
            nestedEntitlementIds.add(line.id)
        }
    }

    const entries: GroupedAccessPathEntry[] = []

    for (const line of lines) {
        if (line.type === 'ROLE' || line.type === 'ACCESS_PROFILE') {
            const contained = line.id ? (containedByGrantor.get(line.id) ?? []) : []
            if (contained.length > 0) {
                entries.push({ kind: 'grantor', grantor: line, contained })
            } else {
                entries.push({ kind: 'standalone', line })
            }
            continue
        }

        if (line.type === 'ENTITLEMENT' && line.id && nestedEntitlementIds.has(line.id)) {
            continue
        }

        entries.push({ kind: 'standalone', line })
    }

    return entries
}

function renderGroupedBodyHtml(entries: GroupedAccessPathEntry[], uiOrigin?: string): string {
    return entries
        .map((entry) =>
            entry.kind === 'grantor'
                ? renderGrantorLineHtml(entry.grantor, entry.contained, uiOrigin)
                : renderStandaloneLineHtml(entry.line, uiOrigin)
        )
        .join('')
}

/** Outcome styling on the removed side: only standalone non-revocable lines stay green. */
function outcomeOnRemovedSide(line: FlatAccessPathLine, underRevocableGrantor = false): OutcomeKind {
    if (underRevocableGrantor) {
        return 'remove'
    }

    return line.revocable ? 'remove' : 'keep'
}

function buildRemovedSideHtml(entries: GroupedAccessPathEntry[], uiOrigin?: string): string {
    return entries
        .map((entry) => {
            if (entry.kind === 'standalone') {
                return wrapOutcomePanel(
                    renderStandaloneLineHtml(entry.line, uiOrigin),
                    outcomeOnRemovedSide(entry.line)
                )
            }

            const grantorRevocable = entry.grantor.revocable
            const grantorPanel = wrapOutcomePanel(
                `<li>${renderLineContent(entry.grantor, false, uiOrigin)} — Contains:</li>`,
                outcomeOnRemovedSide(entry.grantor)
            )
            const containedPanels = entry.contained
                .map((line) =>
                    wrapOutcomePanel(
                        renderLineHtml(line, true, uiOrigin),
                        outcomeOnRemovedSide(line, grantorRevocable),
                        { nested: true }
                    )
                )
                .join('')

            return `${grantorPanel}${containedPanels}`
        })
        .join('')
}

function emptyListHtml(): string {
    return '<p><em>No access paths resolved.</em></p>'
}

/** Renders sod-remediation access paths with grantor Contains lists and plain/outcome variants. */
export function renderFlatAccessPathList(
    lines: FlatAccessPathLine[],
    options: RenderFlatAccessPathListOptions = {}
): SideVariants {
    const prefix = options.sideHintHtml ?? ''

    if (lines.length === 0) {
        const variants = buildBlockSideVariants(emptyListHtml())
        return {
            plain: `${prefix}${variants.plain}`,
            asKept: `${prefix}${variants.asKept}`,
            asRemoved: `${prefix}${variants.asRemoved}`,
        }
    }

    const { uiOrigin } = options
    const entries = groupAccessPathLines(lines)
    const bodyHtml = renderGroupedBodyHtml(entries, uiOrigin)
    const variants = buildSideVariants(bodyHtml)
    return {
        plain: `${prefix}${variants.plain}`,
        asKept: `${prefix}${variants.asKept}`,
        asRemoved: `${prefix}${buildRemovedSideHtml(entries, uiOrigin)}`,
    }
}

/** Renders grouped access path lines as an unordered list body (no outcome variants). */
export function renderFlatAccessPathListBody(
    lines: FlatAccessPathLine[],
    options: Pick<RenderFlatAccessPathListOptions, 'uiOrigin'> = {}
): string {
    if (lines.length === 0) {
        return emptyListHtml()
    }
    return `<ul>${renderGroupedBodyHtml(groupAccessPathLines(lines), options.uiOrigin)}</ul>`
}
