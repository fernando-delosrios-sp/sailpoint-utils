import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { CompensatingControlV1 } from '../../isc/controls'
import { ViolationV1, extractSideEntitlements, resolveViolationSides } from '../../isc/violations'
import { IdentityAccessItem } from '../../isc/identity-access'
import {
    RecommendedSideToCorrect,
    sideCorrectionLabel,
} from './access-path-enrichment'
import { buildRevocableAccessSearchString, ResolvedAccessSide, resolveAccessSide } from './access-path-resolver'
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

function truncateEscaped(text: string, maxLength: number): string {
    if (text.length <= maxLength) {
        return text
    }

    if (maxLength <= 1) {
        return text.slice(0, maxLength)
    }

    return `${text.slice(0, maxLength - 1)}…`
}

function pathConflictPhrase(groupACount: number, groupBCount: number): string {
    const sideLabel = (count: number): string => (count === 1 ? 'access path' : 'access paths')

    if (groupACount === groupBCount) {
        return `${groupACount} ${sideLabel(groupACount)} on each side are in conflict`
    }

    return `${groupACount} and ${groupBCount} ${sideLabel(Math.max(groupACount, groupBCount))} are in conflict`
}

function remediationFormLink(formUrl: string): string {
    const safeFormUrl = escapeHtml(formUrl)
    // Unquoted href: no literal quote chars (DelimitedFile provisionAsCsv-safe); valid when URL has no spaces.
    return `<a href=${safeFormUrl}>Remediate here</a>`
}

/**
 * Compact HTML for persisted `sod-remediation:form-email-body`.
 * Fits ISC STRING storage (256 chars); access-path detail lives in the remediation form.
 */
export function buildPersistedSituationSummary(
    input: SituationSummaryInput,
    formUrl: string,
    maxLength: number = ISC_STRING_ATTRIBUTE_MAX_LENGTH
): string {
    const { violation, groupA, groupB, controls } = input

    let identity = escapeHtml(violation.identity.name ?? violation.identity.id)
    let policy = escapeHtml(violation.policy?.name ?? 'Unknown policy')
    const formLink = remediationFormLink(formUrl)
    const pathPhrase = pathConflictPhrase(groupA.accessPaths.length, groupB.accessPaths.length)

    const render = (identityValue: string, policyValue: string, includeControls: boolean): string => {
        const controlsNote =
            includeControls && controls.length === 0
                ? ' No compensating controls are available.'
                : ''
        return `<p>Please review a SOD violation for ${identityValue} (${policyValue}). ${pathPhrase}.${controlsNote} ${formLink}.</p>`
    }

    if (render(identity, policy, true).length <= maxLength) {
        return render(identity, policy, true)
    }
    if (render(identity, policy, false).length <= maxLength) {
        return render(identity, policy, false)
    }

    const overhead = render('', '', false).length
    const nameBudget = maxLength - overhead
    if (nameBudget > 2) {
        const combinedLength = identity.length + policy.length
        const identityBudget = Math.max(1, Math.floor(nameBudget * (identity.length / combinedLength)))
        const policyBudget = Math.max(1, nameBudget - identityBudget)
        identity = truncateEscaped(identity, identityBudget)
        policy = truncateEscaped(policy, policyBudget)
    }

    const truncated = render(identity, policy, false)
    return truncated.length <= maxLength ? truncated : truncated.slice(0, maxLength)
}

/** Builds full HTML for in-form DESCRIPTION rendering (includes access-path lists). */
export function buildSituationSummary(input: SituationSummaryInput): string {
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
    return controls.map((control) => {
        const option: FormInputSelectOption = {
            label: control.name,
            value: control.id,
        }
        if (control.description) {
            option.sublabel = control.description
        }
        return option
    })
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
        groupAAccessSearch: buildRevocableAccessSearchString(groupA.accessPaths),
        groupBAccessSearch: buildRevocableAccessSearchString(groupB.accessPaths),
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
