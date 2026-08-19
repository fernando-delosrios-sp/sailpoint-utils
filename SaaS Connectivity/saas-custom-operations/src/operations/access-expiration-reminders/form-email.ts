import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'

const WARNING_EMOJI = '⚠️'

export interface FormEmailInput {
    identityDisplayName: string
    accessProfileName: string
    removeDate: string
    daysRemaining: number
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

function reminderFormLink(formUrl: string): string {
    const safeFormUrl = escapeHtml(formUrl)
    return `<a href=${safeFormUrl}>Review here</a>`
}

/** Builds a plain-text email subject for manager expiration reminders. */
export function buildFormEmailHeader(input: Pick<FormEmailInput, 'accessProfileName'>): string {
    const profileName = input.accessProfileName.trim() || 'access profile'
    return `${WARNING_EMOJI} Access Expiration Reminder — ${profileName}`
}

/**
 * Compact HTML for persisted `access-expiration-reminders:form-email-body`.
 * Fits ISC STRING storage (256 chars); assignment detail lives in the reminder form.
 */
export function buildFormEmailBody(
    input: FormEmailInput,
    formUrl: string,
    maxLength: number = ISC_STRING_ATTRIBUTE_MAX_LENGTH
): string {
    let identityName = escapeHtml(input.identityDisplayName.trim() || 'an identity')
    let profileName = escapeHtml(input.accessProfileName.trim() || 'an access profile')
    const daysLabel = input.daysRemaining === 1 ? '1 day' : `${input.daysRemaining} days`
    const formLink = reminderFormLink(formUrl)

    const render = (identityValue: string, profileValue: string): string =>
        `<p>Access profile ${profileValue} for ${identityValue} expires in ${daysLabel}. ${formLink}.</p>`

    if (render(identityName, profileName).length <= maxLength) {
        return render(identityName, profileName)
    }

    const overhead = render('', '').length
    const nameBudget = maxLength - overhead
    if (nameBudget > 2) {
        const combinedLength = Math.max(1, identityName.length + profileName.length)
        const profileBudget = Math.max(1, Math.floor(nameBudget * (profileName.length / combinedLength)))
        const identityBudget = Math.max(1, nameBudget - profileBudget)
        profileName = truncateEscaped(profileName, profileBudget)
        identityName = truncateEscaped(identityName, identityBudget)
    }

    const truncated = render(identityName, profileName)
    return truncated.length <= maxLength ? truncated : truncated.slice(0, maxLength)
}
