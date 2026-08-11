import { AccessPathLine, AccessPathType } from './access-path-resolver'

export const REVOCABILITY_EMOJI = {
    revocable: '✅',
    notRevocable: '🚫',
    keepRecommended: '⭐',
    privileged: '🔐',
    warning: '⚠️',
    info: 'ℹ️',
} as const

function formatAccessTypeLabel(type: AccessPathType): string {
    switch (type) {
        case 'ROLE':
            return 'Role'
        case 'ACCESS_PROFILE':
            return 'Access Profile'
        default:
            return 'Entitlement'
    }
}

function reasonPhrase(line: AccessPathLine, escapeHtml: (text: string) => string): string {
    if (line.grantedVia) {
        const kind = line.grantedVia.type === 'ROLE' ? 'role' : 'access profile'
        return `(granted via ${escapeHtml(line.grantedVia.name)} ${kind})`
    }

    switch (line.reason) {
        case 'granted-via-role':
            return '(granted via role)'
        case 'granted-via-access-profile':
            return '(granted via access profile)'
        default:
            return ''
    }
}

/** Renders one access path line as HTML with emoji revocability and keep labels. */
export function renderAccessPathLineHtml(line: AccessPathLine, escapeHtml: (text: string) => string): string {
    const typeLabel = formatAccessTypeLabel(line.type)
    const label = `${typeLabel}: ${escapeHtml(line.name)}`
    const namePart = `<strong>${label}</strong>`
    const privilegedSuffix =
        line.privileged === true ? ` ${REVOCABILITY_EMOJI.privileged} Privileged` : ''
    const keepSuffix =
        line.keepRecommendation === 'YES'
            ? ` ${REVOCABILITY_EMOJI.keepRecommended} Recommended to keep`
            : ''

    if (line.revocable) {
        return `<li>${namePart}${privilegedSuffix}${keepSuffix} — ${REVOCABILITY_EMOJI.revocable} <span style='color: #27ae60;'>Revocable</span></li>`
    }

    const reason = reasonPhrase(line, escapeHtml)
    const reasonHtml = reason ? ` <em>${reason}</em>` : ''

    return `<li>${namePart}${privilegedSuffix}${keepSuffix} — ${REVOCABILITY_EMOJI.notRevocable} <span style='color: #e67e23;'>Not directly revocable</span>${reasonHtml}</li>`
}

/** Renders access paths as an HTML unordered list. */
export function renderAccessPathListHtml(
    accessPaths: AccessPathLine[],
    escapeHtml: (text: string) => string
): string {
    if (accessPaths.length === 0) {
        return '<p><em>No access paths resolved.</em></p>'
    }

    const items = accessPaths.map((line) => renderAccessPathLineHtml(line, escapeHtml)).join('')
    return `<ul>${items}</ul>`
}

/** Renders a side correction recommendation paragraph when present. */
export function renderSideCorrectionHtml(
    sideLabel: string | null,
    escapeHtml: (text: string) => string
): string {
    if (!sideLabel) {
        return ''
    }

    return `<p><em>${REVOCABILITY_EMOJI.keepRecommended} Recommended to correct ${escapeHtml(sideLabel)} based on keep recommendations on the other side.</em></p>`
}
