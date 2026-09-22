import { describe, expect, it } from 'vitest'
import { deltaPolicies, deltaPolicyNames, unionPolicies, unionPolicyNames } from './policy-name-sets'

describe('violations/policy-name-sets', () => {
    it('unionPolicyNames deduplicates preserving order', () => {
        expect(unionPolicyNames(['A', 'B'], ['B', 'C'])).toEqual(['A', 'B', 'C'])
    })

    it('deltaPolicyNames returns policies in full but not baseline', () => {
        expect(deltaPolicyNames(['A', 'B', 'C'], ['A'])).toEqual(['B', 'C'])
        expect(deltaPolicyNames(['A'], ['A', 'B'])).toEqual([])
    })

    it('unionPolicies fills missing level from a later occurrence of the same name', () => {
        expect(
            unionPolicies([{ name: 'A' }], [{ name: 'A', level: 'HIGH' }, { name: 'B', level: 'LOW' }])
        ).toEqual([
            { name: 'A', level: 'HIGH' },
            { name: 'B', level: 'LOW' },
        ])
    })

    it('deltaPolicies returns policies in full but not baseline', () => {
        expect(
            deltaPolicies(
                [
                    { name: 'A', level: 'HIGH' },
                    { name: 'B', level: 'MEDIUM' },
                ],
                [{ name: 'A' }]
            )
        ).toEqual([{ name: 'B', level: 'MEDIUM' }])
    })
})
