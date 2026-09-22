import { describe, expect, it, vi } from 'vitest'
import { attachSodPolicyLevels } from './resolve-policy-levels'

describe('attachSodPolicyLevels', () => {
    it('fills missing offline levels from the canned catalog', async () => {
        const resolved = await attachSodPolicyLevels(
            {} as never,
            [{ name: 'Finance Control' }, { name: 'Existing Control' }],
            true
        )

        expect(resolved).toEqual([
            { name: 'Finance Control', level: 'HIGH' },
            { name: 'Existing Control', level: 'LOW' },
        ])
    })

    it('keeps a level already present on the policy', async () => {
        const resolved = await attachSodPolicyLevels(
            {} as never,
            [{ name: 'Finance Control', level: 'CRITICAL' }],
            true
        )

        expect(resolved).toEqual([{ name: 'Finance Control', level: 'CRITICAL' }])
    })

    it('looks up a missing connected level by policy id', async () => {
        const getSodPolicyV1 = vi.fn().mockResolvedValue({
            data: { id: 'p-1', name: 'Finance Control', level: 'HIGH' },
        })

        const resolved = await attachSodPolicyLevels(
            { sodPolicies: { getSodPolicyV1 } } as never,
            [{ id: 'p-1', name: 'Finance Control' }],
            false
        )

        expect(getSodPolicyV1).toHaveBeenCalledWith({ id: 'p-1' })
        expect(resolved).toEqual([{ id: 'p-1', name: 'Finance Control', level: 'HIGH' }])
    })

    it('leaves level unset when policy lookup fails', async () => {
        const getSodPolicyV1 = vi.fn().mockRejectedValue(new Error('not found'))

        const resolved = await attachSodPolicyLevels(
            { sodPolicies: { getSodPolicyV1 } } as never,
            [{ id: 'missing', name: 'Unknown Policy' }],
            false
        )

        expect(resolved).toEqual([{ id: 'missing', name: 'Unknown Policy' }])
    })
})
