import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import {
    expandAccessItemsToEntitlementIds,
    parseViolatedPolicyNames,
    predictSodViolationsForIdentity,
} from './predict-violations'
import { predictSodViolationsForIdentityOffline } from './offline-data'

describe('isc/sod-prediction', () => {
    it('predictSodViolationsForIdentity posts IdentityWithNewAccess with ENTITLEMENT refs', async () => {
        const startPredictSodViolationsV1 = vi.fn().mockResolvedValue({
            data: { violationContexts: [] },
        })

        await predictSodViolationsForIdentity({ startPredictSodViolationsV1 } as never, 'identity-1', [
            'ent-a',
            'ent-b',
        ])

        expect(startPredictSodViolationsV1).toHaveBeenCalledWith({
            identityWithNewAccess: {
                identityId: 'identity-1',
                accessRefs: [
                    { id: 'ent-a', type: 'ENTITLEMENT' },
                    { id: 'ent-b', type: 'ENTITLEMENT' },
                ],
            },
        })
    })

    it('parseViolatedPolicyNames extracts policy names from ViolationPrediction', () => {
        const names = parseViolatedPolicyNames({
            violationContexts: [
                { policy: { name: 'Policy A' } },
                { policy: { name: 'Policy B' } },
                { policy: { name: 'Policy A' } },
            ],
        })

        expect(names).toEqual(['Policy A', 'Policy B'])
    })

    it('expandAccessItemsToEntitlementIds expands ROLE and ACCESS_PROFILE via isc modules', async () => {
        const getRoleEntitlementsV1 = vi.fn().mockResolvedValue({ data: [{ id: 'ent-role-1' }] })
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({ data: [{ id: 'ent-ap-1' }] })

        const ids = await expandAccessItemsToEntitlementIds(
            {
                roles: { getRoleEntitlementsV1 } as never,
                accessProfiles: { getAccessProfileEntitlementsV1 } as never,
            },
            [
                { id: 'ent-direct', type: 'ENTITLEMENT' },
                { id: 'role-1', type: 'ROLE' },
                { id: 'ap-1', type: 'ACCESS_PROFILE' },
            ]
        )

        expect(getRoleEntitlementsV1).toHaveBeenCalledWith({ id: 'role-1' })
        expect(getAccessProfileEntitlementsV1).toHaveBeenCalledWith({ id: 'ap-1' })
        expect(ids).toEqual(['ent-direct', 'ent-role-1', 'ent-ap-1'])
    })

    it('predictSodViolationsForIdentity skips predict call when zero entitlements', async () => {
        const startPredictSodViolationsV1 = vi.fn()

        const prediction = await predictSodViolationsForIdentity(
            { startPredictSodViolationsV1 } as never,
            'identity-1',
            []
        )

        expect(startPredictSodViolationsV1).not.toHaveBeenCalled()
        expect(parseViolatedPolicyNames(prediction)).toEqual([])
    })

    it('predictSodViolationsForIdentity throws ConnectorError on API failure', async () => {
        const startPredictSodViolationsV1 = vi.fn().mockRejectedValue({ response: { status: 403 }, message: 'Forbidden' })

        await expect(
            predictSodViolationsForIdentity({ startPredictSodViolationsV1 } as never, 'identity-1', ['ent-1'])
        ).rejects.toBeInstanceOf(ConnectorError)
    })

    it('predictSodViolationsForIdentityOffline returns deterministic offline prediction', () => {
        const prediction = predictSodViolationsForIdentityOffline('offline-identity')

        expect(parseViolatedPolicyNames(prediction)).toEqual(['Finance Control', 'Procurement Control'])
    })
})
