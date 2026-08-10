import { IdentityAccessItem } from './access-path-resolver'
import { ResolvedAccessSide, resolveAccessSide } from './access-path-resolver'
import { CompensatingControlV1, ViolationV1, extractSideEntitlements, resolveViolationSides } from './experimental-client'
import { SodFormInputValues } from './sod-form-service'

export interface SituationSummaryInput {
    violation: ViolationV1
    groupA: ResolvedAccessSide
    groupB: ResolvedAccessSide
    controls: CompensatingControlV1[]
}

/** Builds a plain-text situation summary suitable for workflow email notifications. */
export function buildSituationSummary(input: SituationSummaryInput): string {
    const { violation, groupA, groupB, controls } = input
    const targetName = violation.identity.name ?? violation.identity.id
    const policyName = violation.policy?.name ?? 'Unknown policy'
    const lines = [
        `SOD Violation Remediation Required`,
        ``,
        `Identity: ${targetName}`,
        `Policy: ${policyName}`,
        `Violation ID: ${violation.id}`,
        ``,
        `Group A access paths:`,
        ...groupA.displayLines.map((line) => `  - ${line}`),
        ``,
        `Group B access paths:`,
        ...groupB.displayLines.map((line) => `  - ${line}`),
    ]

    if (controls.length === 0) {
        lines.push('', 'Note: No compensating controls are configured for this tenant.')
    }

    return lines.join('\n')
}

/** Builds HTML context block for the form DESCRIPTION element. */
export function buildSituationSummaryHtml(summary: string): string {
    const escaped = summary
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/\n/g, '<br/>')
    return `<p>${escaped}</p>`
}

export interface AssembleFormInputParams {
    violation: ViolationV1
    groupA: ResolvedAccessSide
    groupB: ResolvedAccessSide
    controls: CompensatingControlV1[]
}

/** Assembles launch-time formInput values from violation context and resolved access paths. */
export function assembleFormInput(params: AssembleFormInputParams): SodFormInputValues {
    const { violation, groupA, groupB, controls } = params
    const summary = buildSituationSummary({ violation, groupA, groupB, controls })

    return {
        targetIdentityName: violation.identity.name ?? violation.identity.id,
        policyName: violation.policy?.name ?? 'Unknown policy',
        situationSummaryHtml: buildSituationSummaryHtml(summary),
        groupADisplay: groupA.displayLines.join('\n'),
        groupBDisplay: groupB.displayLines.join('\n'),
        groupAWarning: groupA.warningText,
        groupBWarning: groupB.warningText,
        hasControls: controls.length > 0,
        violationId: violation.id,
        targetIdentityId: violation.identity.id,
        groupARevokePayload: JSON.stringify(groupA.revokePayload),
        groupBRevokePayload: JSON.stringify(groupB.revokePayload),
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
