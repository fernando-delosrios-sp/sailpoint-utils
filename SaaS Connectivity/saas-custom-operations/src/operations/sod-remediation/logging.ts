import { inspect, InspectOptions } from 'node:util'
import { IdentityAccessItem } from '../../isc/identity-access'
import { CompensatingControlV1 } from '../../isc/controls'
import { ViolationV1 } from '../../isc/violations'
import { ResolvedAccessSide } from './access-path-resolver'
import { SodFormInputValues } from './form-service'

function logInspectOptions(): InspectOptions {
    return {
        depth: null,
        breakLength: Infinity,
        colors: Boolean(process.stdout.isTTY && !process.env.NO_COLOR),
    }
}

function logStep(requestId: string, step: string, detail: Record<string, unknown>): void {
    console.log(`[${requestId}] sod-remediation ${step}`, inspect(detail, logInspectOptions()))
}

/** Logs invocation input (never logs tokens). */
export function logSodRemediationInput(
    requestId: string,
    input: { violationId: string; formName: string; owner?: string },
    offline: boolean
): void {
    logStep(requestId, 'input', {
        violationId: input.violationId,
        formName: input.formName,
        ownerOverride: input.owner ?? null,
        offline,
    })
}

/** Logs violation context after fetch or offline stub selection. */
export function logSodRemediationViolation(requestId: string, violation: ViolationV1, source: 'isc' | 'offline'): void {
    logStep(requestId, 'violation', {
        source,
        id: violation.id,
        owner: violation.owner,
        identity: violation.identity,
        policy: violation.policy ?? null,
        leftSide: violation.leftSide ?? violation.groupA ?? null,
        rightSide: violation.rightSide ?? violation.groupB ?? null,
    })
}

/** Logs tenant compensating controls catalog snapshot. */
export function logSodRemediationControls(requestId: string, controls: CompensatingControlV1[]): void {
    logStep(requestId, 'controls', {
        count: controls.length,
        hasControls: controls.length > 0,
        controls: controls.map((control) => ({ id: control.id, name: control.name })),
    })
}

/** Logs identity access items used for AP/role path expansion. */
export function logSodRemediationIdentityAccess(requestId: string, items: IdentityAccessItem[]): void {
    logStep(requestId, 'identity-access', {
        count: items.length,
        accessProfiles: items.filter((item) => item.type === 'ACCESS_PROFILE').length,
        roles: items.filter((item) => item.type === 'ROLE').length,
        items: items.map((item) => ({
            type: item.type,
            id: item.id,
            name: item.name,
            grantedEntitlementCount: item.grantedEntitlementIds?.length ?? 0,
        })),
    })
}

/** Logs resolved access paths and revoke payloads per side. */
export function logSodRemediationAccessPaths(
    requestId: string,
    groupA: ResolvedAccessSide,
    groupB: ResolvedAccessSide
): void {
    logStep(requestId, 'access-paths', {
        groupA: {
            displayLines: groupA.displayLines,
            warningText: groupA.warningText,
            recommendedRevoke: groupA.revokePayload.recommendedRevoke,
            revokeItemCount: groupA.revokePayload.items.length,
        },
        groupB: {
            displayLines: groupB.displayLines,
            warningText: groupB.warningText,
            recommendedRevoke: groupB.revokePayload.recommendedRevoke,
            revokeItemCount: groupB.revokePayload.items.length,
        },
    })
}

/** Logs recipient resolution outcome. */
export function logSodRemediationRecipient(
    requestId: string,
    recipientId: string,
    source: 'owner-override' | 'violation-owner'
): void {
    logStep(requestId, 'recipient', { recipientId, source })
}

/** Logs form definition ensure result. */
export function logSodRemediationFormDefinition(
    requestId: string,
    formName: string,
    formDefinitionId: string,
    definitionOwnerId: string,
    definitionOwnerSource: 'token-identity' | 'offline-fallback'
): void {
    logStep(requestId, 'form-definition', {
        formName,
        formDefinitionId,
        definitionOwnerId,
        definitionOwnerSource,
    })
}

/** Logs assembled formInput (truncates large HTML field). */
export function logSodRemediationFormInput(requestId: string, formInput: SodFormInputValues): void {
    logStep(requestId, 'form-input', {
        targetIdentityName: formInput.targetIdentityName,
        policyName: formInput.policyName,
        hasControls: formInput.hasControls,
        violationId: formInput.violationId,
        targetIdentityId: formInput.targetIdentityId,
        groupAContentsHtmlPreview:
            formInput.groupAContentsHtml.length > 160
                ? `${formInput.groupAContentsHtml.slice(0, 160)}…`
                : formInput.groupAContentsHtml,
        groupBContentsHtmlPreview:
            formInput.groupBContentsHtml.length > 160
                ? `${formInput.groupBContentsHtml.slice(0, 160)}…`
                : formInput.groupBContentsHtml,
        groupARevokePayload: formInput.groupARevokePayload,
        groupBRevokePayload: formInput.groupBRevokePayload,
        controlOptions: formInput.controlOptions,
        situationSummaryHtmlPreview:
            formInput.situationSummaryHtml.length > 160
                ? `${formInput.situationSummaryHtml.slice(0, 160)}…`
                : formInput.situationSummaryHtml,
    })
}

/** Logs operation output prior to persist. */
export function logSodRemediationOutput(
    requestId: string,
    output: {
        formUrl: string
        situationHeader: string
        situationSummary: string
        ownerEmail: string
    }
): void {
    logStep(requestId, 'output', {
        'sod-remediation:form-url': output.formUrl,
        'sod-remediation:situation-header': output.situationHeader,
        'sod-remediation:situation-summary': output.situationSummary,
        'sod-remediation:owner-email': output.ownerEmail,
        situationSummaryLength: output.situationSummary.length,
    })
}

/** Logs successful completion. */
export function logSodRemediationComplete(requestId: string): void {
    console.log(`[${requestId}] sod-remediation finished`)
}




