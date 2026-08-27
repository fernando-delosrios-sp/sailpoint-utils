import { escapeHtml } from './escape'
import { renderIscUiLink } from './isc-ui-links'
import { REVOCABILITY_EMOJI } from './tokens'

export interface IdentitySodContextPanelInput {
    uiOrigin?: string
    identityId: string
    identityName: string
    policyId?: string
    policyName: string
    violationId: string
    groupAPathsHtml: string
    groupBPathsHtml: string
    hasControls: boolean
    sideHintHtml?: string
}

export interface AccessModelSodContextPanelInput {
    uiOrigin?: string
    accessItemId: string
    accessItemType: 'ROLE' | 'ACCESS_PROFILE'
    accessItemName: string
    policyId: string
    policyName: string
}

function whatWeFoundHeading(): string {
    return '<h3>What we found</h3>'
}

function whatWeNeedHeading(): string {
    return '<h3>What we need from you</h3>'
}

function identityPanelTitle(text: string): string {
    return `<p style='margin:0 0 10px; font-size:1.125rem; font-weight:600;'>${text}</p>`
}

function identityPanelSectionHeading(text: string): string {
    return `<p style='margin:12px 0 6px; font-size:1rem; font-weight:600;'>${text}</p>`
}

function identityPanelSubheading(text: string): string {
    return `<p style='margin:10px 0 4px; font-size:0.9375rem; font-weight:600;'>${text}</p>`
}

/** Builds sod-remediation upper context panel HTML with linked entities when uiOrigin is available. */
export function buildIdentitySodContextPanelHtml(input: IdentitySodContextPanelInput): string {
    const identityLabel = renderIscUiLink(input.uiOrigin, 'identity', input.identityName, input.identityId)
    const policyLabel = renderIscUiLink(input.uiOrigin, 'sodPolicy', input.policyName, input.policyId)
    const violationId = escapeHtml(input.violationId)
    const violationsLink = renderIscUiLink(input.uiOrigin, 'violationList', 'View SOD violations')

    const parts = [
        identityPanelTitle(`${REVOCABILITY_EMOJI.warning} SOD Violation Remediation Required`),
        identityPanelSectionHeading('What we found'),
        `<p><strong>Identity:</strong> ${identityLabel}</p>`,
        `<p><strong>Policy:</strong> ${policyLabel}</p>`,
        `<p><strong>Violation:</strong> ${violationId} · ${violationsLink}</p>`,
        input.sideHintHtml ?? '',
        identityPanelSubheading('Group A access paths'),
        input.groupAPathsHtml,
        identityPanelSubheading('Group B access paths'),
        input.groupBPathsHtml,
    ].filter(Boolean)

    if (!input.hasControls) {
        parts.push(
            `<p><em>${REVOCABILITY_EMOJI.info} Note: No compensating controls are configured for this tenant.</em></p>`
        )
    }

    parts.push(
        identityPanelSectionHeading('What we need from you'),
        input.hasControls
            ? '<p>Choose <strong>Correct</strong> or <strong>Mitigate</strong>, then select which side&apos;s access should be removed to resolve this violation.</p>'
            : '<p>Choose <strong>Correct</strong>, then select which side&apos;s access should be removed to resolve this violation.</p>'
    )

    return parts.join('')
}

/** Builds access-model-sod-remediation upper context panel HTML with linked entities when uiOrigin is available. */
export function buildAccessModelSodContextPanelHtml(input: AccessModelSodContextPanelInput): string {
    const accessItemKind = input.accessItemType === 'ROLE' ? 'role' : 'accessProfile'
    const accessItemLabel = renderIscUiLink(
        input.uiOrigin,
        accessItemKind,
        input.accessItemName,
        input.accessItemId
    )
    const policyLabel = renderIscUiLink(input.uiOrigin, 'sodPolicy', input.policyName, input.policyId)

    return [
        `<h2>${REVOCABILITY_EMOJI.warning} Access Model SoD Remediation Required</h2>`,
        whatWeFoundHeading(),
        `<p><strong>Access item:</strong> ${accessItemLabel}</p>`,
        `<p><strong>Policy:</strong> ${policyLabel}</p>`,
        whatWeNeedHeading(),
        `<p>${REVOCABILITY_EMOJI.info} Select which side&apos;s entitlements should be removed from this access item definition.</p>`,
    ].join('')
}
