import { describe, expect, it, vi } from 'vitest'
import {
    logSodRemediationAccessPaths,
    logSodRemediationControls,
    logSodRemediationFormDefinition,
    logSodRemediationFormInput,
    logSodRemediationOutput,
    logSodRemediationViolation,
} from './logging'

describe('sod-remediation logging', () => {
    it('logs structured operation steps without throwing', () => {
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})

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
            groupAContentsHtml: '<ul><li>✅ Revocable</li></ul>',
            groupBContentsHtml: '<ul><li>✅ Revocable</li></ul>',
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

        expect(logSpy).toHaveBeenCalled()
        expect(logSpy.mock.calls.some((call) => String(call[0]).includes('controls'))).toBe(true)
        expect(logSpy.mock.calls.some((call) => String(call[0]).includes('output'))).toBe(true)

        logSpy.mockRestore()
    })

    it('logs situationSummary as a single string without inspect concatenation breaks', () => {
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})

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

        const outputLog = logSpy.mock.calls.find((call) => String(call[0]).includes('output'))
        expect(outputLog).toBeDefined()
        const logged = String(outputLog?.[1])
        expect(logged).toContain('<h2>⚠️ SOD Violation Remediation Required</h2>')
        expect(logged).toContain('<p><strong>Identity:</strong> Amanda.Ross</p>')
        expect(logged).not.toMatch(/'\s*\+\s*\n/)

        logSpy.mockRestore()
    })

    it('logs form definition owner id and resolution source', () => {
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})

        logSodRemediationFormDefinition(
            'req-log-2',
            'SOD Remediation',
            'def-1',
            'token-owner-id',
            'token-identity'
        )

        const formDefinitionLog = logSpy.mock.calls.find((call) => String(call[0]).includes('form-definition'))
        expect(formDefinitionLog).toBeDefined()
        expect(String(formDefinitionLog?.[1])).toContain("formName: 'SOD Remediation'")
        expect(String(formDefinitionLog?.[1])).toContain("formDefinitionId: 'def-1'")
        expect(String(formDefinitionLog?.[1])).toContain("definitionOwnerId: 'token-owner-id'")
        expect(String(formDefinitionLog?.[1])).toContain("definitionOwnerSource: 'token-identity'")

        logSpy.mockRestore()
    })

    it('logs nested violation entitlements with full inspect depth', () => {
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})

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

        const violationLog = logSpy.mock.calls.find((call) => String(call[0]).includes('violation'))
        expect(violationLog).toBeDefined()
        const output = String(violationLog?.[1])
        expect(output).toContain("id: 'ent-a'")
        expect(output).toContain("name: 'Ent A'")
        expect(output).toContain("id: 'ent-b'")
        expect(output).not.toContain('[Object]')

        logSpy.mockRestore()
    })
})

