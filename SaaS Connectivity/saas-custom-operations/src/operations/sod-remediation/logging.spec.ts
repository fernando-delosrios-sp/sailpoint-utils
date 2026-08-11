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
                displayLines: ['Entitlement: A'],
                warningText: 'warn',
                revokePayload: {
                    items: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'A' }],
                    recommendedRevoke: { type: 'ENTITLEMENT', id: 'ent-a', name: 'A' },
                },
            },
            {
                displayLines: ['Entitlement: B'],
                warningText: 'warn',
                revokePayload: {
                    items: [{ type: 'ENTITLEMENT', id: 'ent-b', name: 'B' }],
                    recommendedRevoke: { type: 'ENTITLEMENT', id: 'ent-b', name: 'B' },
                },
            }
        )
        logSodRemediationFormInput('req-log-1', {
            targetIdentityName: 'Alice',
            policyName: 'Policy',
            situationSummaryHtml: '<p>summary</p>',
            groupAContents: '- A (Entitlement)',
            groupBContents: '- B (Entitlement)',
            groupAWarning: 'w',
            groupBWarning: 'w',
            hasControls: false,
            violationId: 'vio-1',
            targetIdentityId: 'ident-1',
            groupARevokePayload: '{}',
            groupBRevokePayload: '{}',
            controlOptions: [{ label: 'A (Control)', value: 'ctrl-a' }],
        })
        logSodRemediationOutput('req-log-1', 'https://example.com/form/1', 'summary text')

        expect(logSpy).toHaveBeenCalled()
        expect(logSpy.mock.calls.some((call) => String(call[0]).includes('controls'))).toBe(true)
        expect(logSpy.mock.calls.some((call) => String(call[0]).includes('output'))).toBe(true)

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

