import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { SodPolicySummary } from '../../isc/sod-policies'
import { CatalogAccessItem } from '../../isc/roles/list-enabled-roles'
import {
    escapeHtml,
    fitPersistableHtml,
    renderUnquotedHrefCta,
} from '../../lib/persistable-email'

const WARNING_EMOJI = '⚠️'

export interface FormEmailInput {
    accessItem: Pick<CatalogAccessItem, 'id' | 'name' | 'type'>
    policy: Pick<SodPolicySummary, 'id' | 'name'>
    groupAIds: string[]
    groupBIds: string[]
}

function pathConflictPhrase(groupACount: number, groupBCount: number): string {
    const sideLabel = (count: number): string => (count === 1 ? 'entitlement' : 'entitlements')

    if (groupACount === groupBCount) {
        return `${groupACount} ${sideLabel(groupACount)} on each side are in conflict`
    }

    return `${groupACount} and ${groupBCount} ${sideLabel(Math.max(groupACount, groupBCount))} are in conflict`
}

/** Builds a plain-text email subject for workflow notifications. */
export function buildFormEmailHeader(input: Pick<FormEmailInput, 'accessItem' | 'policy'>): string {
    const itemName = input.accessItem.name ?? input.accessItem.id
    return `${WARNING_EMOJI} Access Model SOD Remediation Required — ${itemName}`
}

/**
 * Compact HTML for persisted `access-model-sod-remediation:form-email-body`.
 * Fits ISC STRING storage (256 chars); entitlement detail lives in the remediation form.
 */
export function buildFormEmailBody(
    input: FormEmailInput,
    formUrl: string,
    maxLength: number = ISC_STRING_ATTRIBUTE_MAX_LENGTH
): string {
    const { accessItem, policy, groupAIds, groupBIds } = input

    const itemType = escapeHtml(accessItem.type)
    const formLink = renderUnquotedHrefCta(formUrl, 'Remediate here')
    const pathPhrase = pathConflictPhrase(groupAIds.length, groupBIds.length)

    return fitPersistableHtml({
        slots: {
            itemName: escapeHtml(accessItem.name ?? accessItem.id),
            policyName: escapeHtml(policy.name ?? 'Unknown policy'),
        },
        render: (s) =>
            `<p>Please review an access model policy violation on ${s.itemName} (${itemType}) for policy ${s.policyName}. ${pathPhrase}. ${formLink}.</p>`,
        maxLength,
    })
}
