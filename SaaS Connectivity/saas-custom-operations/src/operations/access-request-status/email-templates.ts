import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { escapeHtml } from '../../lib/sod-form-html'
import type { AccessRequestAnalytics } from './compute-analytics'

const APPROVAL_CENTER_PATH = '/ui/d/approvals/requested-items'
const APPROVAL_CENTER_LABEL = 'ISC Approval Center'

export interface ApprovalEmailContext {
    managerRefName: string
    displayName: string
    requestedItemName: string
    /** Tenant UI origin from `resolveUiOrigin(ctx.apiUrl)`; plain text is rendered when absent. */
    uiOrigin?: string
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

function approvalCenterLink(uiOrigin: string | undefined): string {
    if (!uiOrigin) {
        return APPROVAL_CENTER_LABEL
    }

    return `<a href=${escapeHtml(`${uiOrigin}${APPROVAL_CENTER_PATH}`)}>${APPROVAL_CENTER_LABEL}</a>`
}

/**
 * Compact HTML for persisted `emailBodyHtml`.
 * Fits ISC STRING storage (256 chars); risk analytics detail lives in the ETS pre-approval comment.
 */
export function buildApprovalEmailBody(
    analytics: AccessRequestAnalytics,
    context: ApprovalEmailContext,
    maxLength: number = ISC_STRING_ATTRIBUTE_MAX_LENGTH
): string {
    let managerName = escapeHtml(context.managerRefName.trim() || 'Manager')
    let identityName = escapeHtml(context.displayName.trim() || 'an identity')
    let itemName = escapeHtml(context.requestedItemName.trim() || 'requested access')
    const riskName = escapeHtml(analytics.iscRiskName.trim() || 'N/A')
    const approvalLink = approvalCenterLink(context.uiOrigin)

    const render = (managerValue: string, identityValue: string, itemValue: string): string =>
        `<p>${managerValue}, ${identityValue} requested ${itemValue} (${riskName} risk). Review in ${approvalLink}.</p>`

    if (render(managerName, identityName, itemName).length <= maxLength) {
        return render(managerName, identityName, itemName)
    }

    const overhead = render('', '', '').length
    const nameBudget = maxLength - overhead
    if (nameBudget > 3) {
        const combinedLength = Math.max(1, managerName.length + identityName.length + itemName.length)
        const managerBudget = Math.max(1, Math.floor(nameBudget * (managerName.length / combinedLength)))
        const identityBudget = Math.max(1, Math.floor(nameBudget * (identityName.length / combinedLength)))
        const itemBudget = Math.max(1, nameBudget - managerBudget - identityBudget)
        managerName = truncateEscaped(managerName, managerBudget)
        identityName = truncateEscaped(identityName, identityBudget)
        itemName = truncateEscaped(itemName, itemBudget)
    }

    const truncated = render(managerName, identityName, itemName)
    return truncated.length <= maxLength ? truncated : truncated.slice(0, maxLength)
}
