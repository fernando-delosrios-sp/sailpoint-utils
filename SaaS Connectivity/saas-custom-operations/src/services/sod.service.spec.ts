import { describe, expect, it } from 'vitest'
import { SodService } from './sod.service'
import type { EntitlementRef, SodPolicy } from './types'

describe('SodService', () => {
    it('detects conflicting entitlements across policy sides', () => {
        const sdk = {} as never
        const service = new SodService(sdk)
        const entitlements: EntitlementRef[] = [
            { type: 'ENTITLEMENT', id: 'left-1' },
            { type: 'ENTITLEMENT', id: 'right-1' },
        ]
        const policies: SodPolicy[] = [
            {
                id: 'policy-1',
                name: 'Policy One',
                conflictingAccessCriteria: {
                    leftCriteria: { criteriaList: [{ type: 'ENTITLEMENT', id: 'left-1' }] },
                    rightCriteria: { criteriaList: [{ type: 'ENTITLEMENT', id: 'right-1' }] },
                },
            },
        ]

        const violations = service.checkPoliciesAgainstEntitlements(entitlements, policies)
        expect(violations).toHaveLength(1)
        expect(violations[0]?.policyName).toBe('Policy One')
    })
})
