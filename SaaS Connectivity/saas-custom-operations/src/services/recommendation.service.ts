import { SAILPOINT_EXPERIMENTAL } from '../framework/sdk-factory'
import type { SailPointClients } from '../framework/types'
import type { RequestedItemType } from './types'

export class RecommendationService {
    constructor(private sdk: SailPointClients) {}

    async fetchRecommendations(
        identityId: string,
        itemId: string,
        itemType: RequestedItemType
    ): Promise<{ response?: Array<{ recommendation?: string; interpretations?: string[] }> } | null> {
        try {
            const response = await this.sdk.iaiRecommendations.getRecommendationsV1({
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
            return (response.data as { response?: Array<{ recommendation?: string; interpretations?: string[] }> }) ?? null
        } catch (error) {
            console.error(`[RecommendationService] Error fetching recommendations for item ${itemId}:`, error)
            return null
        }
    }
}
