import { describe, expect, it, vi } from 'vitest'
import { computeAccessRequestAnalytics } from './compute-analytics'
import type { SailPointClients } from '../../framework/types'

vi.mock('../../isc/access-requests/fetch-access-request-by-id', () => ({
    fetchAccessRequestById: vi.fn().mockResolvedValue({
        id: 'item-1',
        type: 'ENTITLEMENT',
        accessRequestId: 'ar-1',
        requestedFor: { id: 'identity-1' },
    }),
}))

vi.mock('../../isc/outliers/fetch-identity-outlier', () => ({
    fetchIdentityOutlier: vi.fn().mockResolvedValue({ score: 0.125 }),
    formatOutlierScore: vi.fn().mockReturnValue('12.50%'),
}))

vi.mock('../../isc/access-requests/entitlement-aggregation', () => ({
    getUnderlyingEntitlements: vi.fn().mockResolvedValue([{ type: 'ENTITLEMENT', id: 'ent-1' }]),
    getPendingEntitlements: vi.fn().mockResolvedValue([]),
}))

vi.mock('../../isc/access-requests/requested-item', () => ({
    getRequestedItemMetadata: vi.fn().mockResolvedValue({
        attributes: [{ key: 'iscRisk', values: [{ name: 'Low' }] }],
    }),
}))

vi.mock('../../isc/sod-policies/list-enforced-policies', () => ({
    listEnforcedSodPolicies: vi.fn().mockResolvedValue([]),
}))

vi.mock('../../isc/sod-policies/check-policies-against-entitlements', () => ({
    checkPoliciesAgainstEntitlements: vi.fn().mockReturnValue([]),
}))

vi.mock('../../isc/sod-prediction/predict-violations', () => ({
    predictSodViolationsForIdentity: vi.fn().mockResolvedValue({ violationContexts: [{ policy: { name: 'Policy A' } }] }),
    parseViolatedPolicyNames: vi.fn().mockReturnValue(['Policy A']),
}))

vi.mock('../../isc/recommendations/fetch-item-recommendations', () => ({
    fetchItemRecommendations: vi.fn().mockResolvedValue({
        response: [{ recommendation: 'YES', interpretations: ['Approved'] }],
    }),
    formatRecommendations: vi.fn().mockReturnValue({
        recommendationsDecision: 'YES',
        recommendationsInterpretations: 'Approved',
    }),
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
        const { fetchAccessRequestById } = await import('../../isc/access-requests/fetch-access-request-by-id')
        vi.mocked(fetchAccessRequestById).mockResolvedValueOnce(null)

        await expect(computeAccessRequestAnalytics({} as SailPointClients, 'missing')).resolves.toBeNull()
    })
})
