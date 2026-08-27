import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { CompensatingControlV1 } from '../../isc/controls'
import { ViolationV1, extractSideEntitlements, resolveViolationSides } from '../../isc/violations'
import { IdentityAccessItem } from '../../isc/identity-access'
import {
    escapeHtml,
    fitPersistableHtml,
    renderUnquotedHrefCta,
} from '../../lib/persistable-email'
import {
    buildGroupColumnLayouts,
    buildIdentitySodContextPanelHtml,
    renderEmojiLegend,
    renderFlatAccessPathList,
    renderFlatAccessPathListBody,
    SideVariants,
} from '../../lib/sod-form-html'
import {
    RecommendedSideToCorrect,
    sideCorrectionLabel,
} from './access-path-enrichment'
import { buildRevocableAccessSearchString, ResolvedAccessSide, resolveAccessSide } from './access-path-resolver'
import { FormInputSelectOption, SodFormInputValues } from './form-service'
import { REVOCABILITY_EMOJI, renderSideCorrectionHtml } from './revocability-labels'

export interface SituationSummaryInput {
    violation: ViolationV1
    groupA: ResolvedAccessSide
    groupB: ResolvedAccessSide
    controls: CompensatingControlV1[]
    recommendedSideToCorrect?: RecommendedSideToCorrect
}

/** Builds a plain-text email subject for workflow notifications. */
export function buildSituationHeader(input: Pick<SituationSummaryInput, 'violation'>): string {
    const targetName = input.violation.identity.name ?? input.violation.identity.id
    return `${REVOCABILITY_EMOJI.warning} SOD Violation Remediation Required — ${targetName}`
}

function pathConflictPhrase(groupACount: number, groupBCount: number): string {
    const sideLabel = (count: number): string => (count === 1 ? 'access path' : 'access paths')

    if (groupACount === groupBCount) {
        return `${groupACount} ${sideLabel(groupACount)} on each side are in conflict`
    }

    return `${groupACount} and ${groupBCount} ${sideLabel(Math.max(groupACount, groupBCount))} are in conflict`
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

    const formLink = renderUnquotedHrefCta(formUrl, 'Remediate here')
    const pathPhrase = pathConflictPhrase(groupA.accessPaths.length, groupB.accessPaths.length)
    const controlsNote =
        controls.length === 0 ? ' No compensating controls are available.' : undefined

    return fitPersistableHtml({
        slots: {
            identity: escapeHtml(violation.identity.name ?? violation.identity.id),
            policy: escapeHtml(violation.policy?.name ?? 'Unknown policy'),
        },
        optionalSuffixes: controlsNote !== undefined ? { controls: controlsNote } : undefined,
        render: (s, suffixes) =>
            `<p>Please review a SOD violation for ${s.identity} (${s.policy}). ${pathPhrase}.${suffixes.controls ?? ''} ${formLink}.</p>`,
        maxLength,
    })
}

function buildSituationSummaryCore(input: SituationSummaryInput, uiOrigin?: string): string {
    const { violation, groupA, groupB, controls, recommendedSideToCorrect = null } = input
    const sideHint = renderSideCorrectionHtml(sideCorrectionLabel(recommendedSideToCorrect), escapeHtml)

    return buildIdentitySodContextPanelHtml({
        uiOrigin,
        identityId: violation.identity.id,
        identityName: violation.identity.name ?? violation.identity.id,
        policyId: violation.policy?.id,
        policyName: violation.policy?.name ?? 'Unknown policy',
        violationId: violation.id,
        groupAPathsHtml: renderFlatAccessPathListBody(groupA.accessPaths, { uiOrigin }),
        groupBPathsHtml: renderFlatAccessPathListBody(groupB.accessPaths, { uiOrigin }),
        hasControls: controls.length > 0,
        sideHintHtml: sideHint || undefined,
    })
}

/** Builds full HTML for in-form DESCRIPTION rendering (includes access-path lists and emoji legend). */
export function buildSituationSummary(input: SituationSummaryInput, uiOrigin?: string): string {
    return `${buildSituationSummaryCore(input, uiOrigin)}${renderEmojiLegend()}`
}

/** Builds HTML summary without emoji legend (for persisted output parity). */
export function buildSituationSummaryWithoutLegend(input: SituationSummaryInput, uiOrigin?: string): string {
    return buildSituationSummaryCore(input, uiOrigin)
}

function buildAccessContentsVariants(
    side: ResolvedAccessSide,
    recommendedSideToCorrect?: RecommendedSideToCorrect,
    sideKey?: 'groupA' | 'groupB',
    uiOrigin?: string
): SideVariants {
    const sideHint =
        sideKey && recommendedSideToCorrect === sideKey
            ? renderSideCorrectionHtml(sideCorrectionLabel(recommendedSideToCorrect), escapeHtml)
            : ''

    return renderFlatAccessPathList(side.accessPaths, { sideHintHtml: sideHint, uiOrigin })
}

/** Builds HTML for a resolved access side form column (plain variant). */
export function buildAccessContentsHtml(
    side: ResolvedAccessSide,
    recommendedSideToCorrect?: RecommendedSideToCorrect,
    sideKey?: 'groupA' | 'groupB',
    uiOrigin?: string
): string {
    return buildAccessContentsVariants(side, recommendedSideToCorrect, sideKey, uiOrigin).plain
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
    uiOrigin?: string
}

/** Assembles launch-time formInput values from violation context and resolved access paths. */
export function assembleFormInput(params: AssembleFormInputParams): SodFormInputValues {
    const { violation, groupA, groupB, controls, recommendedSideToCorrect = null, uiOrigin } = params
    const summary = buildSituationSummary(
        { violation, groupA, groupB, controls, recommendedSideToCorrect },
        uiOrigin
    )
    const groupAVariants = buildAccessContentsVariants(groupA, recommendedSideToCorrect, 'groupA', uiOrigin)
    const groupBVariants = buildAccessContentsVariants(groupB, recommendedSideToCorrect, 'groupB', uiOrigin)
    const layouts = buildGroupColumnLayouts(groupAVariants, groupBVariants)

    return {
        targetIdentityName: violation.identity.name ?? violation.identity.id,
        policyName: violation.policy?.name ?? 'Unknown policy',
        situationSummaryHtml: summary,
        ...layouts,
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
