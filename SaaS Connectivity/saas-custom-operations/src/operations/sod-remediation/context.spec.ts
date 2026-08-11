import { describe, expect, it } from 'vitest'
import {
    assembleFormInput,
    buildAccessContentsHtml,
    buildControlOptions,
    buildSituationHeader,
    buildSituationSummary,
} from './context'
import { ELEVATED_WARNING } from './access-path-resolver'

describe('sod-remediation context', () => {
    const summaryInput = {
        violation: {
            id: 'vio-1',
            owner: { id: 'owner-1' },
            identity: { id: 'ident-1', name: 'Alice Example' },
            policy: { id: 'pol-1', name: 'AP vs AP' },
            leftSide: { entitlements: [{ id: 'ent-a', name: 'Ent A' }] },
            rightSide: { entitlements: [{ id: 'ent-b', name: 'Ent B' }] },
        },
        groupA: {
            accessPaths: [
                {
                    type: 'ENTITLEMENT' as const,
                    id: 'ent-a',
                    name: 'Ent A',
                    revocable: true,
                    recommended: false,
                    reason: 'direct-assignment' as const,
                    privileged: true,
                },
            ],
            displayLines: ['Entitlement: Ent A'],
            warningText: 'standard',
            revokePayload: {
                items: [
                    {
                        type: 'ENTITLEMENT' as const,
                        id: 'ent-a',
                        name: 'Ent A',
                        revocable: true,
                        recommended: false,
                        reason: 'direct-assignment' as const,
                        privileged: true,
                    },
                ],
                recommendedRevoke: {
                    type: 'ENTITLEMENT' as const,
                    id: 'ent-a',
                    name: 'Ent A',
                    revocable: true,
                    recommended: false,
                    reason: 'direct-assignment' as const,
                },
            },
        },
        groupB: {
            accessPaths: [
                {
                    type: 'ENTITLEMENT' as const,
                    id: 'ent-b',
                    name: 'Ent B',
                    revocable: false,
                    recommended: false,
                    reason: 'granted-via-role' as const,
                    grantedVia: { type: 'ROLE' as const, id: 'role-1', name: 'Finance Role' },
                },
                {
                    type: 'ROLE' as const,
                    id: 'role-1',
                    name: 'Finance Role',
                    revocable: true,
                    recommended: false,
                    keepRecommendation: 'YES' as const,
                },
            ],
            displayLines: ['Entitlement: Ent B', 'Role: Finance Role'],
            warningText: ELEVATED_WARNING,
            revokePayload: {
                items: [
                    {
                        type: 'ENTITLEMENT' as const,
                        id: 'ent-b',
                        name: 'Ent B',
                        revocable: false,
                        recommended: false,
                        reason: 'granted-via-role' as const,
                        grantedVia: { type: 'ROLE' as const, id: 'role-1', name: 'Finance Role' },
                    },
                    {
                        type: 'ROLE' as const,
                        id: 'role-1',
                        name: 'Finance Role',
                        revocable: true,
                        recommended: false,
                        keepRecommendation: 'YES' as const,
                    },
                ],
                recommendedRevoke: {
                    type: 'ROLE' as const,
                    id: 'role-1',
                    name: 'Finance Role',
                    revocable: true,
                    recommended: false,
                },
            },
        },
        controls: [{ id: 'ctrl-1', name: 'Control 1' }],
        recommendedSideToCorrect: 'groupA' as const,
    } as const

    it('buildSituationHeader returns plain-text subject with identity name', () => {
        expect(buildSituationHeader(summaryInput)).toBe(
            '⚠️ SOD Violation Remediation Required — Alice Example'
        )
    })

    it('buildSituationSummary returns HTML with keep and revocability emoji labels', () => {
        const summary = buildSituationSummary(summaryInput)

        expect(summary).toContain('⚠️ SOD Violation Remediation Required')
        expect(summary).toContain('<strong>Identity:</strong> Alice Example')
        expect(summary).toContain('✅')
        expect(summary).toContain('Revocable')
        expect(summary).toContain('⭐ Recommended to keep')
        expect(summary).toContain('🔐 Privileged')
        expect(summary).toContain('🚫')
        expect(summary).toContain('Not directly revocable')
        expect(summary).toContain('(granted via Finance Role role)')
        expect(summary).toContain('Recommended to correct Group A')
        expect(summary).not.toContain('⭐ Recommended</span>')
    })

    it('buildSituationSummary escapes HTML in dynamic values', () => {
        const summary = buildSituationSummary({
            ...summaryInput,
            violation: {
                ...summaryInput.violation,
                identity: { id: 'ident-1', name: 'Alice <script>alert(1)</script>' },
            },
        })

        expect(summary).toContain('Alice &lt;script&gt;alert(1)&lt;/script&gt;')
        expect(summary).not.toContain('<script>')
    })

    it('buildSituationSummary notes when no compensating controls exist', () => {
        const summary = buildSituationSummary({ ...summaryInput, controls: [] })

        expect(summary).toContain('ℹ️ Note: No compensating controls are configured for this tenant.')
    })

    it('buildSituationSummary omits newline separators for DelimitedFile CSV persist', () => {
        const summary = buildSituationSummary(summaryInput, {
            formUrl: 'https://tenant.identitynow.com/form/instance-1',
        })

        expect(summary).not.toContain('\n')
        expect(summary).not.toMatch(/(?:href|style)="/)
    })

    it('buildSituationSummary appends remediation form link when formUrl is provided', () => {
        const summary = buildSituationSummary(summaryInput, {
            formUrl: 'https://tenant.identitynow.com/form/instance-1',
        })

        expect(summary).toContain('Remediation form:')
        expect(summary).toContain(
            "<a href='https://tenant.identitynow.com/form/instance-1'>https://tenant.identitynow.com/form/instance-1</a>"
        )
    })

    it('buildSituationSummary omits remediation form link for form instance output', () => {
        const summary = buildSituationSummary(summaryInput)

        expect(summary).not.toContain('Remediation form:')
    })

    it('buildAccessContentsHtml renders side hint on recommended correction side', () => {
        const html = buildAccessContentsHtml(summaryInput.groupA, 'groupA', 'groupA')

        expect(html).toContain('Recommended to correct Group A')
        expect(html).toContain('Ent A')
        expect(html).toContain('Privileged')
    })

    it('assembleFormInput reuses HTML summary without remediation form link', () => {
        const formInput = assembleFormInput(summaryInput)

        expect(formInput.situationSummaryHtml).toBe(buildSituationSummary(summaryInput))
        expect(formInput.situationSummaryHtml).not.toContain('Remediation form:')
        expect(formInput.groupAContentsHtml).toContain('Ent A')
        expect(formInput.groupBContentsHtml).toContain('Not directly revocable')
        expect(formInput.recommendedSideToCorrect).toBe('groupA')
    })

    it('buildControlOptions maps tenant controls to select options', () => {
        expect(
            buildControlOptions([
                { id: 'ctrl-1', name: 'Segregation Review', description: 'Quarterly review' },
                { id: 'ctrl-2', name: 'Manager Attestation' },
            ])
        ).toEqual([
            { label: 'Segregation Review', value: 'ctrl-1', sublabel: 'Quarterly review' },
            { label: 'Manager Attestation', value: 'ctrl-2', sublabel: undefined },
        ])
    })

    it('assembleFormInput includes hidden revoke payloads with keep metadata', () => {
        const formInput = assembleFormInput(summaryInput)

        expect(formInput.hasControls).toBe(true)
        expect(JSON.parse(formInput.groupBRevokePayload).items[1]).toMatchObject({
            keepRecommendation: 'YES',
            recommended: false,
        })
        expect(JSON.parse(formInput.groupBRevokePayload).recommendedRevoke.type).toBe('ROLE')
    })
})
