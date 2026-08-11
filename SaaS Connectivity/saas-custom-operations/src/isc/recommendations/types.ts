export type KeepRecommendation = 'YES' | 'NO' | 'MAYBE' | 'NOT_FOUND'

export type AccessItemRefType = 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'

export interface KeepRecommendationRequest {
    identityId: string
    itemId: string
    itemType: AccessItemRefType
}

export type KeepRecommendationMap = Map<string, KeepRecommendation>

export function keepRecommendationKey(itemId: string, itemType: AccessItemRefType): string {
    return `${itemType}:${itemId}`
}
