import { describe, expect, it } from 'vitest'
import { buildFormEmailBody, buildFormEmailHeader } from './form-email'

describe('access-model-sod-remediation/form-email', () => {
    const input = {
        accessItem: { id: 'role-r', name: 'Finance Role', type: 'ROLE' as const },
        policy: { id: 'policy-p', name: 'AP/AR Separation' },
        groupAIds: ['ent-a'],
        groupBIds: ['ent-c'],
    }

    it('builds a plain-text email header from access model name', () => {
        expect(buildFormEmailHeader(input)).toBe(
            '⚠️ Access Model SOD Remediation Required — Finance Role'
        )
    })

    it('builds HTML email body with escaped text and remediation link', () => {
        const body = buildFormEmailBody(input, 'https://tenant.example/form/1')

        expect(body).toContain('access model policy violation')
        expect(body).toContain('Finance Role')
        expect(body).toContain('AP/AR Separation')
        expect(body).toContain('1 entitlement on each side are in conflict')
        expect(body).toContain('<a href=https://tenant.example/form/1>Remediate here</a>')
    })

    it('escapes HTML in access model and policy names', () => {
        const body = buildFormEmailBody(
            {
                ...input,
                accessItem: { id: 'role-r', name: 'Role <script>', type: 'ROLE' },
                policy: { id: 'policy-p', name: 'Policy "quoted"' },
            },
            'https://tenant.example/form/1'
        )

        expect(body).toContain('Role &lt;script&gt;')
        expect(body).toContain('Policy &quot;quoted&quot;')
        expect(body).not.toContain('<script>')
    })
})
