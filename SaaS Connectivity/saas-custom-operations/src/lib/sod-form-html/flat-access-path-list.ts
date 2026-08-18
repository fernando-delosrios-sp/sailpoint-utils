import { escapeHtml } from './escape'
import { iconSuffix } from './icon-suffix'
import { buildBlockSideVariants, buildSideVariants, SideVariants } from './outcome-panel'
import { renderTypeTag, AccessKind } from './type-tag'
import { REVOCABILITY_EMOJI } from './tokens'

export interface FlatAccessPathLine {
    type: AccessKind
    name: string
    revocable: boolean
    keepRecommendation?: 'YES' | 'MAYBE' | 'NO' | 'NOT_FOUND'
    privileged?: boolean
    grantedVia?: { type: 'ROLE' | 'ACCESS_PROFILE'; name: string }
    reason?: 'direct-assignment' | 'granted-via-role' | 'granted-via-access-profile'
}

export interface RenderFlatAccessPathListOptions {
    /** Optional HTML prefix (e.g. side correction hint) prepended to all variants. */
    sideHintHtml?: string
}

function reasonPhrase(line: FlatAccessPathLine): string {
    if (line.grantedVia) {
        const kind = line.grantedVia.type === 'ROLE' ? 'role' : 'access profile'
        return `(via ${escapeHtml(line.grantedVia.name)} ${kind})`
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

function renderFlatAccessPathLineHtml(line: FlatAccessPathLine): string {
    const namePart = `<strong>${escapeHtml(line.name)}</strong> ${renderTypeTag(line.type)}`
    const icons = renderLineIcons(line)

    if (line.revocable) {
        return `<li>${namePart}${icons}</li>`
    }

    const reason = reasonPhrase(line)
    const reasonHtml = reason ? ` <em>${reason}</em>` : ''
    return `<li>${namePart}${icons}${reasonHtml}</li>`
}

function emptyListHtml(): string {
    return '<p><em>No access paths resolved.</em></p>'
}

/** Renders sod-remediation access paths as flat list HTML with plain and outcome variants. */
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

    const bodyHtml = lines.map((line) => renderFlatAccessPathLineHtml(line)).join('')
    const variants = buildSideVariants(bodyHtml)
    return {
        plain: `${prefix}${variants.plain}`,
        asKept: `${prefix}${variants.asKept}`,
        asRemoved: `${prefix}${variants.asRemoved}`,
    }
}

/** Renders access path lines as a flat unordered list body (no outcome variants). */
export function renderFlatAccessPathListBody(lines: FlatAccessPathLine[]): string {
    if (lines.length === 0) {
        return emptyListHtml()
    }
    return `<ul>${lines.map((line) => renderFlatAccessPathLineHtml(line)).join('')}</ul>`
}
