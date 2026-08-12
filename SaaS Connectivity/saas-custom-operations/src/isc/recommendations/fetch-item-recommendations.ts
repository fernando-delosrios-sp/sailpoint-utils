import { IAIRecommendationsApi } from 'sailpoint-api-client'
import { SAILPOINT_EXPERIMENTAL } from '../../framework/sdk-factory'
import type { RequestedItemType } from '../access-requests/entitlement-types'

export interface RecommendationResponse {
    response?: Array<{ recommendation?: string; interpretations?: string[] }>
}

/** Fetches IAI recommendation for an access request item. */
export async function fetchItemRecommendations(
    iaiRecommendations: IAIRecommendationsApi,
    identityId: string,
    itemId: string,
    itemType: RequestedItemType
): Promise<RecommendationResponse | null> {
    try {
        const response = await iaiRecommendations.getRecommendationsV1({
            recommendationRequestDto: {
                requests: [
                    {
                        identityId,
                        item: {
                            id: itemId,
                            type: itemType,
                        },
                    },
                ],
            },
            xSailPointExperimental: SAILPOINT_EXPERIMENTAL,
        })
        return (response.data as RecommendationResponse) ?? null
    } catch (error) {
        console.error(`[fetchItemRecommendations] Error fetching recommendations for item ${itemId}:`, error)
        return null
    }
}

/** Formats recommendation API response into workflow-safe strings. */
export function formatRecommendations(recommendations: RecommendationResponse | null): {
    recommendationsDecision: string
    recommendationsInterpretations: string
} {
    const recResponses = recommendations?.response ?? []
    if (recResponses.length === 0 || !recResponses[0]) {
        return {
            recommendationsDecision: 'N/A',
            recommendationsInterpretations: 'N/A',
        }
    }

    const firstRecommendation = recResponses[0]
    return {
        recommendationsDecision: firstRecommendation.recommendation ?? 'N/A',
        recommendationsInterpretations: firstRecommendation.interpretations?.length
            ? firstRecommendation.interpretations.join(' | ')
            : 'N/A',
    }
}
