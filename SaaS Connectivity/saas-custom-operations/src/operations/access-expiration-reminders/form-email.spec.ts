import { describe, expect, it } from 'vitest'
import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { buildFormEmailBody, buildFormEmailHeader } from './form-email'

describe('access-expiration-reminders/form-email', () => {
    const input = {
        identityDisplayName: 'Offline User One',
        accessProfileName: 'SAP Suite',
        removeDate: '2026-08-20T12:00:00.000Z',
        daysRemaining: 1,
    }

    it('builds a plain-text email header from access profile name', () => {
        expect(buildFormEmailHeader(input)).toBe('⚠️ Access Expiration Reminder — SAP Suite')
    })

    it('builds HTML email body with escaped text and form link', () => {
        const body = buildFormEmailBody(input, 'https://tenant.example/form/1')

        expect(body).toContain('SAP Suite')
        expect(body).toContain('Offline User One')
        expect(body).toContain('expires in 1 day')
        expect(body).toContain('<a href=https://tenant.example/form/1>Review here</a>')
        expect(body.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
    })

    it('escapes HTML in identity and access profile names', () => {
        const body = buildFormEmailBody(
            {
                ...input,
                identityDisplayName: 'User <script>',
                accessProfileName: 'Profile "quoted"',
            },
            'https://tenant.example/form/1'
        )

        expect(body).toContain('User &lt;script&gt;')
        expect(body).toContain('Profile &quot;quoted&quot;')
        expect(body).not.toContain('<script>')
    })

    it('truncates long names to stay within ISC string attribute max length', () => {
        const body = buildFormEmailBody(
            {
                ...input,
                identityDisplayName: 'I'.repeat(200),
                accessProfileName: 'P'.repeat(200),
            },
            'https://tenant.example/form/1'
        )

        expect(body.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(body).toContain('Review here')
    })
})
