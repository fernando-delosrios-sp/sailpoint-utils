import { describe, expect, it, vi } from 'vitest'
import { SODPoliciesApi } from 'sailpoint-api-client'
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
})
