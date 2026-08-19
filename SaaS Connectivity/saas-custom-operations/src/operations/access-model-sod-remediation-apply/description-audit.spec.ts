import { describe, expect, it } from 'vitest'
import { buildDescriptionAuditLine } from './description-audit'

describe('buildDescriptionAuditLine', () => {
    it('Description appended on apply', () => {
        const line = buildDescriptionAuditLine({
            policyName: 'Finance vs AP',
            policyId: 'pol-1',
            remediationSide: 'groupB',
            formInstanceId: 'fi-1',
            detachedProfiles: [
                {
                    id: 'ap-x',
                    name: 'SAP Suite',
                    offendingEntitlementNames: ['Accounts Payable'],
                },
            ],
            removedEntitlements: [],
            comments: 'Approved',
            submitterId: 'owner-1',
            timestamp: '2026-08-18T10:00:00.000Z',
        })

        expect(line).toContain('Policy "Finance vs AP" (pol-1)')
        expect(line).toContain('detached access profile "SAP Suite" (ap-x)')
        expect(line).toContain('form instance fi-1')
        expect(line).toContain('comments: Approved')
        expect(line.startsWith('[SOD remediation 2026-08-18T10:00:00.000Z]')).toBe(true)
    })

    it('includes removed direct entitlements without replacing prior description semantics', () => {
        const line = buildDescriptionAuditLine({
            policyName: 'Policy',
            policyId: 'p-1',
            remediationSide: 'groupA',
            formInstanceId: 'fi-2',
            detachedProfiles: [],
            removedEntitlements: [{ id: 'ent-a', name: 'Buyer' }],
            timestamp: '2026-08-18T10:00:00.000Z',
        })

        expect(line).toContain('removed direct entitlements: "Buyer" (ent-a)')
    })
})
