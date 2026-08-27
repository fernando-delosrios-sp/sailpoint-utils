/**
 * Workflow-facing companion to a launched standalone form instance.
 * emailBody is opaque — builders remain at call sites.
 */
export type FormNotification = {
    formUrl: string
    emailHeader: string
    emailBody: string
    emailRecipients: string[]
}

/**
 * Maps a form notification envelope to namespaced persist attributes.
 * Prefix is the operation slug without trailing colon (e.g. `sod-remediation`).
 */
export function toPersistAttributes(
    prefix: string,
    envelope: FormNotification
): Record<string, string | string[]> {
    return {
        [`${prefix}:form-url`]: envelope.formUrl,
        [`${prefix}:form-email-header`]: envelope.emailHeader,
        [`${prefix}:form-email-body`]: envelope.emailBody,
        [`${prefix}:form-email-recipients`]: envelope.emailRecipients,
    }
}
