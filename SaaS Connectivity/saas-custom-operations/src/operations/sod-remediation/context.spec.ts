import { describe, expect, it } from 'vitest'
import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import {
    assembleFormInput,
    buildAccessContentsHtml,
    buildControlOptions,
    buildPersistedSituationSummary,
    buildSituationHeader,
    buildSituationSummary,
} from './context'
import { ELEVATED_WARNING, resolveAccessSide } from './access-path-resolver'

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

    it('buildSituationSummary returns HTML with icon suffixes and emoji legend', () => {
        const summary = buildSituationSummary(summaryInput)

        expect(summary).toContain('⚠️ SOD Violation Remediation Required')
        expect(summary).toContain('What we found')
        expect(summary).toContain('What we need from you')
        expect(summary).toContain('<strong>Identity:</strong> Alice Example')
        expect(summary).toContain('🔐 ✅')
        expect(summary).toContain('⭐ ✅')
        expect(summary).toContain('🚫')
        expect(summary).not.toContain('Revocable')
        expect(summary).not.toContain('Recommended to keep')
        expect(summary).toContain('— Contains:')
        expect(summary).toMatch(/Finance Role[\s\S]*Ent B/)
        expect(summary).not.toContain('(via Finance Role role)')
        expect(summary).toContain('Recommended to correct Group A')
        expect(summary).toContain('Legend:')
        expect(summary).toContain('privileged')
        expect(summary).toContain('<strong>Violation:</strong> vio-1 · ')
        expect(summary).toContain('View SOD violations')
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

    it('buildSituationSummary omits newlines for DelimitedFile form input', () => {
        const summary = buildSituationSummary(summaryInput)

        expect(summary).not.toContain('\n')
    })

    it('In-form summary allows quoted link attributes when uiOrigin is available', () => {
        const uiOrigin = 'https://tenant.example.com'
        const summary = buildSituationSummary(summaryInput, uiOrigin)

        expect(summary).toContain('href="https://tenant.example.com/ui/a/admin/identities/ident-1/details/attributes"')
        expect(summary).toContain('target="_blank"')
        expect(summary).toContain('rel="noopener noreferrer"')
    })

    it('Offline summary omits admin links', () => {
        const summary = buildSituationSummary(summaryInput, undefined)

        expect(summary).toContain('Alice Example')
        expect(summary).not.toMatch(/href=/)
    })

    const sampleFormUrl = 'https://tenant.identitynow.com/form/instance-1'

    it('buildPersistedSituationSummary stays within ISC STRING limit', () => {
        const summary = buildPersistedSituationSummary(summaryInput, sampleFormUrl)

        expect(summary.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(summary).toContain('Please review a SOD violation for Alice Example (AP vs AP)')
        expect(summary).toMatch(/access paths?.*in conflict/)
        expect(summary).toContain(`<a href=${sampleFormUrl}>Remediate here</a>`)
        expect(summary).not.toMatch(/['"]/)
        expect(summary).not.toContain('<ul>')
    })

    it('buildPersistedSituationSummary includes controls note when it fits', () => {
        const summary = buildPersistedSituationSummary({ ...summaryInput, controls: [] }, sampleFormUrl)

        expect(summary.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(summary).toContain('No compensating controls are available')
        expect(summary).toContain(`<a href=${sampleFormUrl}>Remediate here</a>`)
    })

    it('buildPersistedSituationSummary keeps long identity and policy names when form URL fits', () => {
        const summary = buildPersistedSituationSummary(
            {
                ...summaryInput,
                violation: {
                    ...summaryInput.violation,
                    identity: { id: 'ident-1', name: 'A'.repeat(40) },
                    policy: { id: 'pol-1', name: 'P'.repeat(40) },
                },
            },
            sampleFormUrl
        )

        expect(summary.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(summary).toContain('access paths are in conflict')
        expect(summary).toContain('A'.repeat(40))
        expect(summary).toContain('P'.repeat(40))
        expect(summary).toContain(`<a href=${sampleFormUrl}>Remediate here</a>`)
    })

    it('buildPersistedSituationSummary truncates names but keeps actionable form link', () => {
        const summary = buildPersistedSituationSummary(
            {
                ...summaryInput,
                violation: {
                    ...summaryInput.violation,
                    identity: { id: 'ident-1', name: 'A'.repeat(120) },
                    policy: { id: 'pol-1', name: 'P'.repeat(120) },
                },
            },
            sampleFormUrl
        )

        expect(summary.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(summary).toContain(`<a href=${sampleFormUrl}>Remediate here</a>`)
        expect(summary).toContain('…')
    })

    it('buildSituationSummary does not include remediation form link', () => {
        const summary = buildSituationSummary(summaryInput)

        expect(summary).not.toContain('Remediation form:')
    })

    it('buildAccessContentsHtml renders side hint on recommended correction side', () => {
        const html = buildAccessContentsHtml(summaryInput.groupA, 'groupA', 'groupA')

        expect(html).toContain('Recommended to correct Group A')
        expect(html).toContain('Ent A')
        expect(html).toContain('🔐')
        expect(html).toContain('entitlement')
    })

    it('assembleFormInput reuses HTML summary without remediation form link', () => {
        const formInput = assembleFormInput(summaryInput)

        expect(formInput.situationSummaryHtml).toBe(buildSituationSummary(summaryInput))
        expect(formInput.situationSummaryHtml).not.toContain('Remediation form:')
    })

    it('Linked path line names when online', () => {
        const uiOrigin = 'https://tenant.example.com'
        const formInput = assembleFormInput({ ...summaryInput, uiOrigin })

        expect(formInput.groupColumnsHtmlPlain).toContain(
            '/ui/a/admin/access/entitlements/landing-page/details/ent-a'
        )
    })

    it('assembleFormInput colors non-revocable lines green on removed side preview', () => {
        const formInput = assembleFormInput(summaryInput)

        expect(formInput.groupColumnsHtmlWhenGroupBRemoved).toContain('#ffebee')
        expect(formInput.groupColumnsHtmlWhenGroupBRemoved).toContain('#e8f5e9')
        expect(formInput.groupColumnsHtmlWhenGroupBRemoved).toContain('Ent B')
        expect(formInput.groupColumnsHtmlWhenGroupBRemoved).toContain('Finance Role')
        expect(formInput.groupColumnsHtmlWhenGroupBRemoved).toContain('— Contains:')
        expect(formInput.groupColumnsHtmlWhenGroupARemoved).toContain('#ffebee')
        expect(formInput.groupColumnsHtmlWhenGroupARemoved).toContain('Ent A')
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

    it('assembleFormInput includes hidden access search strings for each side', () => {
        const formInput = assembleFormInput(summaryInput)

        expect(formInput.hasControls).toBe(true)
        expect(formInput.groupAAccessSearch).toBe('id:ent-a')
        expect(formInput.groupBAccessSearch).toBe('id:role-1')
    })

    it('Assigned access profile is not a parent access item in form HTML', () => {
        const groupA = resolveAccessSide(
            [{ id: 'ent-a', name: 'Ent A' }],
            [{ type: 'ACCESS_PROFILE', id: 'ap-1', name: 'Finance AP', grantedEntitlementIds: ['ent-a'] }]
        )
        const formInput = assembleFormInput({
            ...summaryInput,
            groupA,
        })
        const summary = buildSituationSummary({
            ...summaryInput,
            groupA,
        })

        expect(formInput.groupAAccessSearch).toBe('id:ent-a')
        expect(formInput.groupAAccessSearch).not.toContain('ap-1')
        expect(formInput.situationSummaryHtml).not.toContain('Finance AP')
        expect(formInput.situationSummaryHtml).not.toContain('access profile')
        expect(formInput.groupColumnsHtmlPlain).not.toContain('Finance AP')
        expect(formInput.groupColumnsHtmlWhenGroupARemoved).not.toContain('Finance AP')
        expect(summary).not.toContain('Finance AP')
        expect(summary).not.toMatch(/Finance AP[\s\S]*Contains/)
    })
})
