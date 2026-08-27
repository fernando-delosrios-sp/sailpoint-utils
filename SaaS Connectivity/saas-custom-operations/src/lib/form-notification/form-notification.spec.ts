import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'
import { toPersistAttributes, type FormNotification } from './index'

const ISC_OR_FORMS_IMPORT = /from ['"][^'"]*\/isc\/|sailpoint-api-client|FormsApi|createFormInstance/

const sampleEnvelope = (): FormNotification => ({
    formUrl: 'https://tenant.identitynow.com/ui/a/admin/forms/new/form-instances/instance-1',
    emailHeader: 'Please remediate SOD violation',
    emailBody: '<p>Compact HTML body</p>',
    emailRecipients: ['owner@example.com', 'backup@example.com'],
})

describe('form-notification toPersistAttributes', () => {
    it('Persist attribute mapping: maps sod-remediation prefix to four canonical keys', () => {
        const envelope = sampleEnvelope()
        const attrs = toPersistAttributes('sod-remediation', envelope)

        expect(attrs).toEqual({
            'sod-remediation:form-url': envelope.formUrl,
            'sod-remediation:form-email-header': envelope.emailHeader,
            'sod-remediation:form-email-body': envelope.emailBody,
            'sod-remediation:form-email-recipients': envelope.emailRecipients,
        })
        expect(Array.isArray(attrs['sod-remediation:form-email-recipients'])).toBe(true)
    })

    it('Access-model prefix mapping: uses access-model-sod-remediation with the same suffixes', () => {
        const envelope = sampleEnvelope()
        const attrs = toPersistAttributes('access-model-sod-remediation', envelope)

        expect(attrs).toEqual({
            'access-model-sod-remediation:form-url': envelope.formUrl,
            'access-model-sod-remediation:form-email-header': envelope.emailHeader,
            'access-model-sod-remediation:form-email-body': envelope.emailBody,
            'access-model-sod-remediation:form-email-recipients': envelope.emailRecipients,
        })
    })

    it('Expiration reminders prefix mapping: uses access-expiration-reminders with the same suffixes', () => {
        const envelope = sampleEnvelope()
        const attrs = toPersistAttributes('access-expiration-reminders', envelope)

        expect(attrs).toEqual({
            'access-expiration-reminders:form-url': envelope.formUrl,
            'access-expiration-reminders:form-email-header': envelope.emailHeader,
            'access-expiration-reminders:form-email-body': envelope.emailBody,
            'access-expiration-reminders:form-email-recipients': envelope.emailRecipients,
        })
    })

    it('Recipients remain string array: single recipient stays a one-element string[]', () => {
        const envelope: FormNotification = {
            ...sampleEnvelope(),
            emailRecipients: ['sole@example.com'],
        }
        const attrs = toPersistAttributes('sod-remediation', envelope)
        const recipients = attrs['sod-remediation:form-email-recipients']

        expect(recipients).toEqual(['sole@example.com'])
        expect(typeof recipients).not.toBe('string')
        expect(Array.isArray(recipients)).toBe(true)
    })

    it('No ISC side effects: mapper does not call ISC or Forms APIs', () => {
        const attrs = toPersistAttributes('sod-remediation', sampleEnvelope())
        expect(Object.keys(attrs)).toHaveLength(4)

        const source = readFileSync(join(__dirname, 'index.ts'), 'utf8')
        expect(source).not.toMatch(ISC_OR_FORMS_IMPORT)
    })
})
