import { describe, expect, it } from 'vitest'
import { parseStatePolicyFilter, resolveSodPolicyListFilters } from './policy-list-filter'

describe('resolveSodPolicyListFilters', () => {
    it('routes state-only scope to client-side filtering', () => {
        expect(resolveSodPolicyListFilters('state eq "ENFORCED"')).toEqual({
            clientState: 'ENFORCED',
        })
    })

    it('passes id and name filters to the list API', () => {
        expect(resolveSodPolicyListFilters('name eq "Finance SOD"')).toEqual({
            apiFilters: 'name eq "Finance SOD"',
        })
    })

    it('parses NOT_ENFORCED state filters', () => {
        expect(parseStatePolicyFilter('state eq NOT_ENFORCED')).toBe('NOT_ENFORCED')
    })
})
