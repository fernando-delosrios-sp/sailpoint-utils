import { CompensatingControlV1 } from '../../isc/controls'
import { ViolationV1, extractSideEntitlements, resolveViolationSides } from '../../isc/violations'
import { IdentityAccessItem } from '../../isc/identity-access'
import {
    RecommendedSideToCorrect,
    sideCorrectionLabel,
} from './access-path-enrichment'
import { ResolvedAccessSide, resolveAccessSide } from './access-path-resolver'
import { FormInputSelectOption, SodFormInputValues } from './form-service'
import {
    REVOCABILITY_EMOJI,
    renderAccessPathListHtml,
    renderSideCorrectionHtml,
} from './revocability-labels'

export interface SituationSummaryInput {
    violation: ViolationV1
    groupA: ResolvedAccessSide
    groupB: ResolvedAccessSide
    controls: CompensatingControlV1[]
    recommendedSideToCorrect?: RecommendedSideToCorrect
}

function escapeHtml(text: string): string {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
}

/** Builds a plain-text email subject for workflow notifications. */
export function buildSituationHeader(input: Pick<SituationSummaryInput, 'violation'>): string {
    const targetName = input.violation.identity.name ?? input.violation.identity.id
    return `${REVOCABILITY_EMOJI.warning} SOD Violation Remediation Required — ${targetName}`
}

export interface BuildSituationSummaryOptions {
    /** When set, appends a clickable remediation form link for email output. */
    formUrl?: string
}

/** Builds an HTML situation summary suitable for workflow email notifications. */
export function buildSituationSummary(
    input: SituationSummaryInput,
    options: BuildSituationSummaryOptions = {}
): string {
    const { violation, groupA, groupB, controls, recommendedSideToCorrect = null } = input
    const targetName = escapeHtml(violation.identity.name ?? violation.identity.id)
    const policyName = escapeHtml(violation.policy?.name ?? 'Unknown policy')
    const violationId = escapeHtml(violation.id)
    const sideHint = renderSideCorrectionHtml(sideCorrectionLabel(recommendedSideToCorrect), escapeHtml)

    const parts = [
        `<h2>${REVOCABILITY_EMOJI.warning} SOD Violation Remediation Required</h2>`,
        `<p><strong>Identity:</strong> ${targetName}</p>`,
        `<p><strong>Policy:</strong> ${policyName}</p>`,
        `<p><strong>Violation ID:</strong> ${violationId}</p>`,
        sideHint,
        '<h3>Group A access paths</h3>',
        renderAccessPathListHtml(groupA.accessPaths, escapeHtml),
        '<h3>Group B access paths</h3>',
        renderAccessPathListHtml(groupB.accessPaths, escapeHtml),
    ].filter(Boolean)

    if (controls.length === 0) {
        parts.push(
            `<p><em>${REVOCABILITY_EMOJI.info} Note: No compensating controls are configured for this tenant.</em></p>`
        )
    }

    if (options.formUrl) {
        const formUrl = escapeHtml(options.formUrl)
        // Single-quoted attrs: DelimitedFile provisionAsCsv breaks on double quotes inside attribute values.
        parts.push(`<p><strong>Remediation form:</strong> <a href='${formUrl}'>${formUrl}</a></p>`)
    }

    // Single-line HTML: DelimitedFile provisionAsCsv breaks on embedded newlines in attribute values.
    return parts.join('')
}

/** Builds HTML for a resolved access side form column. */
export function buildAccessContentsHtml(
    side: ResolvedAccessSide,
    recommendedSideToCorrect?: RecommendedSideToCorrect,
    sideKey?: 'groupA' | 'groupB'
): string {
    const sideHint =
        sideKey && recommendedSideToCorrect === sideKey
            ? renderSideCorrectionHtml(sideCorrectionLabel(recommendedSideToCorrect), escapeHtml)
            : ''

    return `${sideHint}${renderAccessPathListHtml(side.accessPaths, escapeHtml)}`
}

/** Builds FORM_INPUT select options for tenant compensating controls. */
export function buildControlOptions(controls: CompensatingControlV1[]): FormInputSelectOption[] {
    return controls.map((control) => ({
        label: control.name,
        value: control.id,
        sublabel: control.description,
    }))
}

export interface AssembleFormInputParams {
    violation: ViolationV1
    groupA: ResolvedAccessSide
    groupB: ResolvedAccessSide
    controls: CompensatingControlV1[]
    recommendedSideToCorrect?: RecommendedSideToCorrect
}

/** Assembles launch-time formInput values from violation context and resolved access paths. */
export function assembleFormInput(params: AssembleFormInputParams): SodFormInputValues {
    const { violation, groupA, groupB, controls, recommendedSideToCorrect = null } = params
    const summary = buildSituationSummary({ violation, groupA, groupB, controls, recommendedSideToCorrect })

    return {
        targetIdentityName: violation.identity.name ?? violation.identity.id,
        policyName: violation.policy?.name ?? 'Unknown policy',
        situationSummaryHtml: summary,
        groupAContentsHtml: buildAccessContentsHtml(groupA, recommendedSideToCorrect, 'groupA'),
        groupBContentsHtml: buildAccessContentsHtml(groupB, recommendedSideToCorrect, 'groupB'),
        hasControls: controls.length > 0,
        violationId: violation.id,
        targetIdentityId: violation.identity.id,
        groupARevokePayload: JSON.stringify(groupA.revokePayload),
        groupBRevokePayload: JSON.stringify(groupB.revokePayload),
        recommendedSideToCorrect: recommendedSideToCorrect ?? '',
        controlOptions: buildControlOptions(controls),
    }
}

export interface ResolveViolationAccessParams {
    violation: ViolationV1
    identityAccess: IdentityAccessItem[]
}

/** Resolves both violation sides into display lists and revoke payloads. */
export function resolveViolationAccessPaths(params: ResolveViolationAccessParams): {
    groupA: ResolvedAccessSide
    groupB: ResolvedAccessSide
} {
    const { violation, identityAccess } = params
    const sides = resolveViolationSides(violation)
    return {
        groupA: resolveAccessSide(extractSideEntitlements(sides.groupA), identityAccess),
        groupB: resolveAccessSide(extractSideEntitlements(sides.groupB), identityAccess),
    }
}
