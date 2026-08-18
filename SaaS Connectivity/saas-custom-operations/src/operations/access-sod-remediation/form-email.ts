import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { SodPolicySummary } from '../../isc/sod-policies'
import { CatalogAccessItem } from '../../isc/roles/list-enabled-roles'

const WARNING_EMOJI = '⚠️'

export interface FormEmailInput {
    accessItem: Pick<CatalogAccessItem, 'id' | 'name' | 'type'>
    policy: Pick<SodPolicySummary, 'id' | 'name'>
    groupAIds: string[]
    groupBIds: string[]
}

function escapeHtml(text: string): string {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
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
    const sideLabel = (count: number): string => (count === 1 ? 'entitlement' : 'entitlements')

    if (groupACount === groupBCount) {
        return `${groupACount} ${sideLabel(groupACount)} on each side are in conflict`
    }

    return `${groupACount} and ${groupBCount} ${sideLabel(Math.max(groupACount, groupBCount))} are in conflict`
}

function remediationFormLink(formUrl: string): string {
    const safeFormUrl = escapeHtml(formUrl)
    return `<a href=${safeFormUrl}>Remediate here</a>`
}

/** Builds a plain-text email subject for workflow notifications. */
export function buildFormEmailHeader(input: Pick<FormEmailInput, 'accessItem' | 'policy'>): string {
    const itemName = input.accessItem.name ?? input.accessItem.id
    return `${WARNING_EMOJI} Access Model SOD Remediation Required — ${itemName}`
}

/**
 * Compact HTML for persisted `access-sod-remediation:form-email-body`.
 * Fits ISC STRING storage (256 chars); entitlement detail lives in the remediation form.
 */
export function buildFormEmailBody(
    input: FormEmailInput,
    formUrl: string,
    maxLength: number = ISC_STRING_ATTRIBUTE_MAX_LENGTH
): string {
    const { accessItem, policy, groupAIds, groupBIds } = input

    let itemName = escapeHtml(accessItem.name ?? accessItem.id)
    let policyName = escapeHtml(policy.name ?? 'Unknown policy')
    const itemType = escapeHtml(accessItem.type)
    const formLink = remediationFormLink(formUrl)
    const pathPhrase = pathConflictPhrase(groupAIds.length, groupBIds.length)

    const render = (itemValue: string, policyValue: string): string =>
        `<p>Please review an intrinsic SOD violation on access item ${itemValue} (${itemType}) for policy ${policyValue}. ${pathPhrase}. ${formLink}.</p>`

    if (render(itemName, policyName).length <= maxLength) {
        return render(itemName, policyName)
    }

    const overhead = render('', '').length
    const nameBudget = maxLength - overhead
    if (nameBudget > 2) {
        const combinedLength = itemName.length + policyName.length
        const itemBudget = Math.max(1, Math.floor(nameBudget * (itemName.length / combinedLength)))
        const policyBudget = Math.max(1, nameBudget - itemBudget)
        itemName = truncateEscaped(itemName, itemBudget)
        policyName = truncateEscaped(policyName, policyBudget)
    }

    const truncated = render(itemName, policyName)
    return truncated.length <= maxLength ? truncated : truncated.slice(0, maxLength)
}
