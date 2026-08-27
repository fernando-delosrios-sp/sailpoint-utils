import { describe, expect, it } from 'vitest'
import { deltaPolicyNames, unionPolicyNames } from './policy-name-sets'

describe('violations/policy-name-sets', () => {
    it('unionPolicyNames deduplicates preserving order', () => {
        expect(unionPolicyNames(['A', 'B'], ['B', 'C'])).toEqual(['A', 'B', 'C'])
    })

    it('deltaPolicyNames returns policies in full but not baseline', () => {
        expect(deltaPolicyNames(['A', 'B', 'C'], ['A'])).toEqual(['B', 'C'])
        expect(deltaPolicyNames(['A'], ['A', 'B'])).toEqual([])
    })
})
