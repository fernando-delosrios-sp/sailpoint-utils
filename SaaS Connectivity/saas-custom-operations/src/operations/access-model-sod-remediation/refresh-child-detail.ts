import { AccessModelSodConflictDetail } from './conflict-detail'

/** Written at form launch and never recomputed on a refresh, so a stored form stays reachable. */
export interface StoredNotificationFields {
    'access-model-sod-remediation:form-url'?: string
    'access-model-sod-remediation:form-email-header'?: string
    'access-model-sod-remediation:form-email-body'?: string
    'access-model-sod-remediation:form-email-recipients'?: string[]
}

export type RefreshedChildAttributes = AccessModelSodConflictDetail & StoredNotificationFields

function readString(attributes: Record<string, unknown> | undefined, key: string): string | undefined {
    const value = attributes?.[key]
    return typeof value === 'string' && value.length > 0 ? value : undefined
}

function readStringArray(attributes: Record<string, unknown> | undefined, key: string): string[] | undefined {
    const value = attributes?.[key]
    if (Array.isArray(value)) {
        const strings = value.filter((entry): entry is string => typeof entry === 'string')
        return strings.length > 0 ? strings : undefined
    }

    return typeof value === 'string' && value.length > 0 ? [value] : undefined
}

/**
 * Attributes for re-persisting a conflict the scan skipped: current detail, stored notification.
 * Persist replaces the account, so anything the refresh omits is lost.
 */
export function buildRefreshedChildAttributes(
    storedAttributes: Record<string, unknown> | undefined,
    detail: AccessModelSodConflictDetail
): RefreshedChildAttributes {
    const formUrl = readString(storedAttributes, 'access-model-sod-remediation:form-url')
    const emailHeader = readString(storedAttributes, 'access-model-sod-remediation:form-email-header')
    const emailBody = readString(storedAttributes, 'access-model-sod-remediation:form-email-body')
    const recipients = readStringArray(storedAttributes, 'access-model-sod-remediation:form-email-recipients')

    return {
        ...(formUrl ? { 'access-model-sod-remediation:form-url': formUrl } : {}),
        ...(emailHeader ? { 'access-model-sod-remediation:form-email-header': emailHeader } : {}),
        ...(emailBody ? { 'access-model-sod-remediation:form-email-body': emailBody } : {}),
        ...(recipients ? { 'access-model-sod-remediation:form-email-recipients': recipients } : {}),
        ...detail,
    }
}

/** Recipient id from a stored account, used when the current scan cannot resolve an owner. */
export function storedRecipientId(storedAttributes: Record<string, unknown> | undefined): string | undefined {
    return readString(storedAttributes, 'access-model-sod-remediation:recipient-id')
}
