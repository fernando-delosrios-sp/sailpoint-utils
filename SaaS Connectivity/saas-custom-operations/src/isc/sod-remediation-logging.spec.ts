import { describe, expect, it, vi } from 'vitest'
import {
    logSodRemediationAccessPaths,
    logSodRemediationControls,
    logSodRemediationFormDefinition,
    logSodRemediationFormInput,
    logSodRemediationOutput,
} from './sod-remediation-logging'

describe('sod-remediation-logging', () => {
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
            groupADisplay: 'A',
            groupBDisplay: 'B',
            groupAWarning: 'w',
            groupBWarning: 'w',
            hasControls: false,
            violationId: 'vio-1',
            targetIdentityId: 'ident-1',
            groupARevokePayload: '{}',
            groupBRevokePayload: '{}',
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

        expect(logSpy).toHaveBeenCalledWith(
            '[req-log-2] sod-remediation form-definition',
            expect.objectContaining({
                formName: 'SOD Remediation',
                formDefinitionId: 'def-1',
                definitionOwnerId: 'token-owner-id',
                definitionOwnerSource: 'token-identity',
            })
        )

        logSpy.mockRestore()
    })
})

