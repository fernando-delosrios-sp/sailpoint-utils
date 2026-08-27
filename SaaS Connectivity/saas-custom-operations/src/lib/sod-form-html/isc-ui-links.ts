import { escapeHtml } from './escape'

export type IscUiLinkKind =
    | 'identity'
    | 'sodPolicy'
    | 'role'
    | 'accessProfile'
    | 'entitlement'
    | 'violationList'

const PATH_BUILDERS: Record<IscUiLinkKind, (id?: string) => string> = {
    identity: (id) => `/ui/a/admin/identities/${encodeURIComponent(id!)}/details/attributes`,
    sodPolicy: (id) => `/ui/sod/policy-management/${encodeURIComponent(id!)}/details`,
    role: (id) => `/ui/a/admin/access/roles/landing-page/details/${encodeURIComponent(id!)}`,
    accessProfile: (id) => `/ui/a/admin/access/access-profiles/landing-page/details/${encodeURIComponent(id!)}`,
    entitlement: (id) => `/ui/a/admin/access/entitlements/landing-page/details/${encodeURIComponent(id!)}`,
    violationList: () => '/ui/sod/violations',
}

/** Derives tenant UI origin from loopback apiUrl by removing the `.api.` hostname segment when present. */
export function resolveUiOrigin(apiUrl: string): string | undefined {
    const trimmed = apiUrl.trim()
    if (!trimmed) {
        return undefined
    }

    try {
        const parsed = new URL(trimmed)
        const hostname = parsed.hostname.includes('.api.') ? parsed.hostname.replace('.api.', '.') : parsed.hostname
        return `${parsed.protocol}//${hostname}`
    } catch {
        return undefined
    }
}

function buildHref(uiOrigin: string, kind: IscUiLinkKind, id?: string): string {
    return `${uiOrigin}${PATH_BUILDERS[kind](id)}`
}

/** Renders an ISC admin UI anchor, or plain escaped text when offline or id is missing (except violationList). */
export function renderIscUiLink(
    uiOrigin: string | undefined,
    kind: IscUiLinkKind,
    label: string,
    id?: string
): string {
    const escapedLabel = escapeHtml(label)

    if (!uiOrigin) {
        return escapedLabel
    }

    if (kind !== 'violationList' && !id) {
        return escapedLabel
    }

    const href = escapeHtml(buildHref(uiOrigin, kind, id))
    return `<a href="${href}" target="_blank" rel="noopener noreferrer">${escapedLabel}</a>`
}

/** Maps access kind to ISC admin link kind for line renderers. */
export function accessKindToLinkKind(type: 'ROLE' | 'ACCESS_PROFILE' | 'ENTITLEMENT'): IscUiLinkKind {
    switch (type) {
        case 'ROLE':
            return 'role'
        case 'ACCESS_PROFILE':
            return 'accessProfile'
        default:
            return 'entitlement'
    }
}
