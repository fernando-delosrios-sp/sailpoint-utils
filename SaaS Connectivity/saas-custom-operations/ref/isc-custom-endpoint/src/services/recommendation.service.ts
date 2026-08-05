import { SailPointClient } from '../api/sailpoint.client.js';
import type { RecommendationRequestBody, RecommendationApiResponse } from '../api/api.types.js';

export class RecommendationService {
  constructor(private client: SailPointClient) {}

  /**
   * Ruft Empfehlungen (YES/NO/MAYBE) für die angeforderten Items ab.
   * Nutzt den Pfad: /recommendations/v1/request mit dem X-SailPoint-Experimental Header.
   */
  async fetchRecommendations(
    identityId: string, 
    itemId: string, 
    itemType: 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'
  ): Promise<RecommendationApiResponse | null> {
    try {
      const body: RecommendationRequestBody = {
        requests: [
          {
            identityId,
            item: {
              id: itemId,
              type: itemType
            }
          }
        ]
      };

      return await this.client.request<RecommendationApiResponse>(
        'recommendations',
        'v1',
        '/request',
        {
          method: 'POST',
          body: JSON.stringify(body)
        },
        true // <-- Schaltet den X-SailPoint-Experimental Header im Client aktiv
      );
    } catch (e) {
      console.error(`[RecommendationService] Error fetching recommendations for item ${itemId}:`, e);
      return null;
    }
  }
}
