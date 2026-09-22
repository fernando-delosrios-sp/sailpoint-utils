import { describe, expect, it, vi } from 'vitest'
import { EXPERIMENTAL_HEADER } from '../http'
import { listActiveViolationPoliciesForIdentity, listActiveViolationPolicyNamesForIdentity } from './list-active-policy-names'

describe('violations/list-active-policy-names', () => {
    it('listActiveViolationPolicyNamesForIdentity calls GET /violations/v1 with identity filter', async () => {
        const fetchFn = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => [
                { policy: { name: 'Finance Control' } },
                { policy: { name: 'Finance Control' } },
                { policy: { name: 'Procurement Control' } },
            ],
        })

        const names = await listActiveViolationPolicyNamesForIdentity(
            {
                apiUrl: 'https://tenant.api.identitynow.com',
                token: 'token',
                fetchFn,
            },
            'identity-1'
        )

        expect(fetchFn).toHaveBeenCalledWith(
            expect.stringContaining('/violations/v1?filters='),
            expect.objectContaining({
                headers: expect.objectContaining({
                    Authorization: 'Bearer token',
                    [EXPERIMENTAL_HEADER]: 'true',
                }),
            })
        )
        expect(names).toEqual(['Finance Control', 'Procurement Control'])
    })

    it('captures policy level from the violation list payload', async () => {
        const fetchFn = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => [{ policy: { id: 'p-1', name: 'Finance Control', level: 'HIGH' } }],
        })

        const policies = await listActiveViolationPoliciesForIdentity(
            {
                apiUrl: 'https://tenant.api.identitynow.com',
                token: 'token',
                fetchFn,
            },
            'identity-1'
        )

        expect(policies).toEqual([{ id: 'p-1', name: 'Finance Control', level: 'HIGH' }])
    })
})
