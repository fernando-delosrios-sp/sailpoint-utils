import { describe, expect, it, vi } from 'vitest'
import {
    logSodRemediationAccessPaths,
    logSodRemediationControls,
    logSodRemediationFormDefinition,
    logSodRemediationFormInput,
    logSodRemediationIdentityAccess,
    logSodRemediationOutput,
    logSodRemediationViolation,
} from './logging'

const { mockLogger } = vi.hoisted(() => ({
    mockLogger: {
        info: vi.fn(),
        warn: vi.fn(),
        error: vi.fn(),
    },
}))

vi.mock('../../framework/logger', () => ({
    getActiveFrameworkLogger: vi.fn(() => mockLogger),
}))

describe('sod-remediation logging', () => {
    it('logs structured operation steps through the framework logger', () => {
        logSodRemediationControls('req-log-1', [{ id: 'ctrl-1', name: 'Control 1' }])
        logSodRemediationAccessPaths(
            'req-log-1',
            {
                accessPaths: [
                    {
                        type: 'ENTITLEMENT',
                        id: 'ent-a',
                        name: 'A',
                        revocable: true,
                        recommended: true,
                    },
                ],
                displayLines: ['Entitlement: A'],
                warningText: 'warn',
                revokePayload: {
                    items: [
                        {
                            type: 'ENTITLEMENT',
                            id: 'ent-a',
                            name: 'A',
                            revocable: true,
                            recommended: true,
                        },
                    ],
                    recommendedRevoke: {
                        type: 'ENTITLEMENT',
                        id: 'ent-a',
                        name: 'A',
                        revocable: true,
                        recommended: true,
                    },
                },
            },
            {
                accessPaths: [
                    {
                        type: 'ENTITLEMENT',
                        id: 'ent-b',
                        name: 'B',
                        revocable: true,
                        recommended: true,
                    },
                ],
                displayLines: ['Entitlement: B'],
                warningText: 'warn',
                revokePayload: {
                    items: [
                        {
                            type: 'ENTITLEMENT',
                            id: 'ent-b',
                            name: 'B',
                            revocable: true,
                            recommended: true,
                        },
                    ],
                    recommendedRevoke: {
                        type: 'ENTITLEMENT',
                        id: 'ent-b',
                        name: 'B',
                        revocable: true,
                        recommended: true,
                    },
                },
            }
        )
        logSodRemediationFormInput('req-log-1', {
            targetIdentityName: 'Alice',
            policyName: 'Policy',
            situationSummaryHtml: '<p>summary</p>',
            groupColumnsHtmlWhenGroupARemoved: '<div style=remove>A</div>',
            groupColumnsHtmlWhenGroupBRemoved: '<div style=remove>B</div>',
            hasControls: false,
            violationId: 'vio-1',
            targetIdentityId: 'ident-1',
            groupAAccessSearch: 'id:ent-a',
            groupBAccessSearch: 'id:ent-b',
            controlOptions: [{ label: 'A (Control)', value: 'ctrl-a' }],
        })
        logSodRemediationOutput('req-log-1', {
            formUrl: 'https://example.com/form/1',
            situationHeader: '⚠️ SOD Violation Remediation Required — Alice',
            situationSummary: 'summary text',
            ownerEmail: 'owner@example.com',
        })

        expect(mockLogger.info).toHaveBeenCalled()
        expect(mockLogger.info.mock.calls.some((call) => String(call[0]).includes('controls'))).toBe(true)
        expect(mockLogger.info.mock.calls.some((call) => String(call[0]).includes('output'))).toBe(true)
    })

    it('logs situationSummary as a single string in output detail', () => {
        const situationSummary = [
            '<h2>⚠️ SOD Violation Remediation Required</h2>',
            '<p><strong>Identity:</strong> Amanda.Ross</p>',
            '<ul><li><strong>Entitlement: CommerceSession</strong> — not revocable</li></ul>',
        ].join('\n')

        logSodRemediationOutput('req-log-summary', {
            formUrl: 'https://example.com/form/1',
            situationHeader: '⚠️ SOD Violation Remediation Required — Amanda.Ross',
            situationSummary,
            ownerEmail: 'owner@example.com',
        })

        const outputCall = mockLogger.info.mock.calls.find((call) => String(call[0]).includes('output'))
        expect(outputCall).toBeDefined()
        const detail = outputCall?.[1] as Record<string, unknown>
        expect(detail['sod-remediation:form-email-body']).toBe(situationSummary)
    })

    it('logs form definition owner id and resolution source', () => {
        logSodRemediationFormDefinition(
            'req-log-2',
            'SOD Remediation',
            'def-1',
            'token-owner-id',
            'token-identity'
        )

        const formDefinitionCall = mockLogger.info.mock.calls.find((call) =>
            String(call[0]).includes('form-definition')
        )
        expect(formDefinitionCall).toBeDefined()
        expect(formDefinitionCall?.[1]).toMatchObject({
            formName: 'SOD Remediation',
            formDefinitionId: 'def-1',
            definitionOwnerId: 'token-owner-id',
            definitionOwnerSource: 'token-identity',
        })
    })

    it('logs identity-access role counts without accessProfiles', () => {
        logSodRemediationIdentityAccess('req-log-ia', [
            { type: 'ROLE', id: 'role-1', name: 'Finance Role', grantedEntitlementIds: ['ent-1'] },
        ])

        const identityAccessCall = mockLogger.info.mock.calls.find((call) =>
            String(call[0]).includes('identity-access')
        )
        expect(identityAccessCall?.[1]).toMatchObject({ count: 1, roles: 1 })
        expect(identityAccessCall?.[1]).not.toHaveProperty('accessProfiles')
    })

    it('logs nested violation entitlements in detail', () => {
        logSodRemediationViolation(
            'req-log-3',
            {
                id: 'vio-1',
                owner: { id: 'owner-1', name: 'Owner' },
                identity: { id: 'ident-1', name: 'Alice' },
                policy: { id: 'pol-1', name: 'Policy' },
                leftSide: {
                    name: 'Buyer',
                    entitlements: [{ id: 'ent-a', name: 'Ent A', type: 'ENTITLEMENT' }],
                },
                rightSide: {
                    name: 'Payments',
                    entitlements: [
                        { id: 'ent-b', name: 'Ent B', type: 'ENTITLEMENT' },
                        { id: 'ent-c', name: 'Ent C', type: 'ENTITLEMENT' },
                    ],
                },
            },
            'isc'
        )

        const violationCall = mockLogger.info.mock.calls.find((call) => String(call[0]).includes('violation'))
        expect(violationCall).toBeDefined()
        const detail = violationCall?.[1] as {
            leftSide?: { entitlements?: Array<{ id: string }> }
            rightSide?: { entitlements?: Array<{ id: string }> }
        }
        expect(detail.leftSide?.entitlements?.[0]?.id).toBe('ent-a')
        expect(detail.rightSide?.entitlements?.some((item) => item.id === 'ent-b')).toBe(true)
    })
})
