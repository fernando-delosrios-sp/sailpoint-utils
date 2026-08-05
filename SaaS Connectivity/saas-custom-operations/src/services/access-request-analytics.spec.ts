import { describe, expect, it, vi } from 'vitest'
import { computeAccessRequestAnalytics } from './access-request-analytics'
import type { SailPointClients } from '../framework/types'

vi.mock('./access.service', () => ({
    AccessService: vi.fn().mockImplementation(() => ({
        fetchAccessRequestById: vi.fn().mockResolvedValue({
            id: 'item-1',
            type: 'ENTITLEMENT',
            accessRequestId: 'ar-1',
            requestedFor: { id: 'identity-1' },
        }),
        fetchOutlierByIdentityId: vi.fn().mockResolvedValue({ score: 0.125 }),
        buildPayload: vi.fn().mockReturnValue({ getAccessRequestStatus: {}, getXdrData: { score: 0.125 } }),
        getUnderlyingEntitlements: vi.fn().mockResolvedValue([{ type: 'ENTITLEMENT', id: 'ent-1' }]),
        getPendingEntitlements: vi.fn().mockResolvedValue([]),
        getRequestedItemMetadata: vi.fn().mockResolvedValue({
            attributes: [{ key: 'iscRisk', values: [{ name: 'Low' }] }],
        }),
    })),
}))

vi.mock('./sod.service', () => ({
    SodService: vi.fn().mockImplementation(() => ({
        fetchSodPolicies: vi.fn().mockResolvedValue([]),
        checkPoliciesAgainstEntitlements: vi.fn().mockReturnValue([]),
        predictSodViolations: vi.fn().mockResolvedValue([{ policy: { name: 'Policy A' } }]),
    })),
}))

vi.mock('./recommendation.service', () => ({
    RecommendationService: vi.fn().mockImplementation(() => ({
        fetchRecommendations: vi.fn().mockResolvedValue({
            response: [{ recommendation: 'YES', interpretations: ['Approved'] }],
        }),
    })),
}))

describe('computeAccessRequestAnalytics', () => {
    it('returns workflow-safe analytics strings', async () => {
        const result = await computeAccessRequestAnalytics({} as SailPointClients, 'ar-1')

        expect(result).toMatchObject({
            iscRiskName: 'Low',
            xdrScore: '12.50%',
            sodPrediction: 'Policy A',
            recommendationsDecision: 'YES',
            recommendationsInterpretations: 'Approved',
        })
    })

    it('returns null when access request is missing required fields', async () => {
        const { AccessService } = await import('./access.service')
        vi.mocked(AccessService).mockImplementationOnce(
            () =>
                ({
                    fetchAccessRequestById: vi.fn().mockResolvedValue(null),
                }) as never
        )

        await expect(computeAccessRequestAnalytics({} as SailPointClients, 'missing')).resolves.toBeNull()
    })
})
