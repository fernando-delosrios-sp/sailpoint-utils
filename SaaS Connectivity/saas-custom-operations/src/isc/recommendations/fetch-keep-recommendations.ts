import { type IscClientConfig, iscPost } from '../http'
import {
    keepRecommendationKey,
    type AccessItemRefType,
    type KeepRecommendation,
    type KeepRecommendationMap,
    type KeepRecommendationRequest,
} from './types'

interface RecommendationApiResponse {
    response?: Array<{
        request?: {
            identityId?: string
            item?: { id?: string; type?: string }
        }
        recommendation?: KeepRecommendation
    }>
}

/** Fetches ISC keep recommendations for identity access items in a single batch call. */
export async function fetchKeepRecommendations(
    config: IscClientConfig,
    requests: KeepRecommendationRequest[]
): Promise<KeepRecommendationMap> {
    if (requests.length === 0) {
        return new Map()
    }

    const body = {
        requests: requests.map((request) => ({
            identityId: request.identityId,
            item: { id: request.itemId, type: request.itemType },
        })),
        excludeInterpretations: true,
    }

    const result = await iscPost<RecommendationApiResponse>(config, '/recommendations/v1/request', body)
    const map: KeepRecommendationMap = new Map()

    for (const entry of result.response ?? []) {
        const itemId = entry.request?.item?.id
        const itemType = entry.request?.item?.type as AccessItemRefType | undefined
        if (!itemId || !itemType || !entry.recommendation) {
            continue
        }
        map.set(keepRecommendationKey(itemId, itemType), entry.recommendation)
    }

    return map
}
