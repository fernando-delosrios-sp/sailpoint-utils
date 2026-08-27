import { describe, expect, it, vi } from 'vitest'
import { fetchKeepRecommendations } from './fetch-keep-recommendations'
import { fetchKeepRecommendationsOffline } from './offline-data'
import { keepRecommendationKey } from './types'

describe('isc/recommendations', () => {
    it('fetchKeepRecommendations calls POST /recommendations/v1/request and maps responses', async () => {
        const fetchFn = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => ({
                response: [
                    {
                        request: { identityId: 'ident-1', item: { id: 'role-1', type: 'ROLE' } },
                        recommendation: 'YES',
                    },
                    {
                        request: { identityId: 'ident-1', item: { id: 'ent-1', type: 'ENTITLEMENT' } },
                        recommendation: 'MAYBE',
                    },
                ],
            }),
        })

        const map = await fetchKeepRecommendations(
            {
                apiUrl: 'https://tenant.api.identitynow.com/',
                token: 'tok',
                fetchFn,
            },
            [
                { identityId: 'ident-1', itemId: 'role-1', itemType: 'ROLE' },
                { identityId: 'ident-1', itemId: 'ent-1', itemType: 'ENTITLEMENT' },
            ]
        )

        expect(fetchFn).toHaveBeenCalledWith(
            'https://tenant.api.identitynow.com/recommendations/v1/request',
            expect.objectContaining({ method: 'POST' })
        )
        expect(map.get(keepRecommendationKey('role-1', 'ROLE'))).toBe('YES')
        expect(map.get(keepRecommendationKey('ent-1', 'ENTITLEMENT'))).toBe('MAYBE')
    })

    it('fetchKeepRecommendations returns empty map for no requests', async () => {
        const fetchFn = vi.fn()
        const map = await fetchKeepRecommendations(
            { apiUrl: 'https://tenant.api.identitynow.com/', token: 'tok', fetchFn },
            []
        )

        expect(fetchFn).not.toHaveBeenCalled()
        expect(map.size).toBe(0)
    })

    it('fetchKeepRecommendationsOffline returns canned YES for offline entitlement B', () => {
        const map = fetchKeepRecommendationsOffline([
            { identityId: 'offline-identity', itemId: 'offline-ent-a', itemType: 'ENTITLEMENT' },
            { identityId: 'offline-identity', itemId: 'offline-ent-b', itemType: 'ENTITLEMENT' },
        ])

        expect(map.get(keepRecommendationKey('offline-ent-a', 'ENTITLEMENT'))).toBe('NO')
        expect(map.get(keepRecommendationKey('offline-ent-b', 'ENTITLEMENT'))).toBe('YES')
    })
})
