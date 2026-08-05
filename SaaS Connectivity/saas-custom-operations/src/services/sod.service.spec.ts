import { describe, expect, it, vi } from 'vitest'
import { SodService } from './sod.service'
import type { SailPointClients } from '../framework/types'
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

    it('fetchSodPolicies returns enforced policies from SDK', async () => {
        const policies: SodPolicy[] = [{ id: 'policy-1', name: 'Policy One' }]
        const sdk = {
            sodPolicies: {
                listSodPoliciesV1: vi.fn().mockResolvedValue({ data: policies }),
            },
        } as unknown as SailPointClients

        const service = new SodService(sdk)
        await expect(service.fetchSodPolicies()).resolves.toEqual(policies)
        expect(sdk.sodPolicies.listSodPoliciesV1).toHaveBeenCalledWith({
            limit: 250,
            filters: 'state eq "ENFORCED"',
        })
    })

    it('fetchSodPolicies returns empty array when SDK call fails', async () => {
        const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined)
        const sdk = {
            sodPolicies: {
                listSodPoliciesV1: vi.fn().mockRejectedValue(new Error('network failure')),
            },
        } as unknown as SailPointClients

        const service = new SodService(sdk)
        await expect(service.fetchSodPolicies()).resolves.toEqual([])
        expect(consoleError).toHaveBeenCalled()

        consoleError.mockRestore()
    })

    it('predictSodViolations maps access refs and returns SDK data', async () => {
        const predicted = [{ policy: { name: 'Policy A' } }]
        const startPredictSodViolationsV1 = vi.fn().mockResolvedValue({ data: predicted })
        const sdk = {
            sodViolations: { startPredictSodViolationsV1 },
        } as unknown as SailPointClients

        const service = new SodService(sdk)
        await expect(
            service.predictSodViolations('identity-1', [
                { id: 'ent-1', type: 'ENTITLEMENT' },
                { id: 'role-1', type: 'ROLE' },
            ])
        ).resolves.toEqual(predicted)

        expect(startPredictSodViolationsV1).toHaveBeenCalledWith({
            identityWithNewAccess: {
                identityId: 'identity-1',
                accessRefs: [
                    { id: 'ent-1', type: 'ENTITLEMENT' },
                    { id: 'role-1', type: 'ENTITLEMENT' },
                ],
            },
        })
    })

    it('predictSodViolations returns null when SDK call fails', async () => {
        const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined)
        const sdk = {
            sodViolations: {
                startPredictSodViolationsV1: vi.fn().mockRejectedValue(new Error('predict failed')),
            },
        } as unknown as SailPointClients

        const service = new SodService(sdk)
        await expect(service.predictSodViolations('identity-1', [{ id: 'ent-1', type: 'ENTITLEMENT' }])).resolves.toBeNull()
        expect(consoleError).toHaveBeenCalled()

        consoleError.mockRestore()
    })
})
