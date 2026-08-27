import {
    keepRecommendationKey,
    type KeepRecommendationMap,
    type KeepRecommendationRequest,
} from './types'

/** Canned keep recommendations for offline SOD remediation invokes. */
export function fetchKeepRecommendationsOffline(requests: KeepRecommendationRequest[]): KeepRecommendationMap {
    const map: KeepRecommendationMap = new Map()

    for (const request of requests) {
        const key = keepRecommendationKey(request.itemId, request.itemType)
        if (request.itemId === 'offline-ent-b' && request.itemType === 'ENTITLEMENT') {
            map.set(key, 'YES')
        } else {
            map.set(key, 'NO')
        }
    }

    return map
}
