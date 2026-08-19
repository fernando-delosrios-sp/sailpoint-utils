import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it } from 'vitest'
import {
    parseStatePolicyFilter,
    resolveSodPolicyListFilters,
    UNSUPPORTED_POLICY_SCOPE_MESSAGE,
} from './policy-list-filter'

describe('resolveSodPolicyListFilters', () => {
    it('routes state-only scope to client-side filtering', () => {
        expect(resolveSodPolicyListFilters('state eq "ENFORCED"')).toEqual({
            clientState: 'ENFORCED',
        })
    })

    it('Non-state filters pass to API', () => {
        expect(resolveSodPolicyListFilters('name eq "Finance SOD"')).toEqual({
            apiFilters: 'name eq "Finance SOD"',
        })
    })

    it('Unsupported compound state scope rejected', () => {
        expect(() => resolveSodPolicyListFilters('state eq "ENFORCED" and name sw "Finance"')).toThrow(
            ConnectorError
        )
        expect(() => resolveSodPolicyListFilters('state eq "ENFORCED" and name sw "Finance"')).toThrow(
            UNSUPPORTED_POLICY_SCOPE_MESSAGE
        )
    })

    it('parses NOT_ENFORCED state filters', () => {
        expect(parseStatePolicyFilter('state eq NOT_ENFORCED')).toBe('NOT_ENFORCED')
    })
})
