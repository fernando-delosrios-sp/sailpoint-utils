import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { SODPoliciesApi } from 'sailpoint-api-client'
import { UNSUPPORTED_POLICY_SCOPE_MESSAGE } from './policy-list-filter'
import { listSodPolicies } from './list-policies'

describe('listSodPolicies', () => {
    it('filters ENFORCED policies client-side when state filter is requested', async () => {
        const listSodPoliciesV1 = vi
            .fn()
            .mockResolvedValueOnce({
                data: [
                    { id: 'p1', name: 'Enforced Policy', state: 'ENFORCED' },
                    { id: 'p2', name: 'Draft Policy', state: 'NOT_ENFORCED' },
                ],
            })
            .mockResolvedValueOnce({ data: [] })

        const sodPolicies = { listSodPoliciesV1 } as unknown as SODPoliciesApi
        const result = await listSodPolicies(sodPolicies, 'state eq "ENFORCED"')

        expect(listSodPoliciesV1).toHaveBeenCalledWith({ offset: 0, limit: 250 })
        expect(result).toEqual([{ id: 'p1', name: 'Enforced Policy', state: 'ENFORCED' }])
    })

    it('surfaces ConnectorError for unsupported compound state policyScope', async () => {
        const listSodPoliciesV1 = vi.fn()
        const sodPolicies = { listSodPoliciesV1 } as unknown as SODPoliciesApi

        await expect(
            listSodPolicies(sodPolicies, 'state eq "ENFORCED" and name sw "Finance"')
        ).rejects.toSatisfy((error: unknown) => {
            expect(error).toBeInstanceOf(ConnectorError)
            expect((error as ConnectorError).message).toBe(UNSUPPORTED_POLICY_SCOPE_MESSAGE)
            return true
        })

        expect(listSodPoliciesV1).not.toHaveBeenCalled()
    })
})
