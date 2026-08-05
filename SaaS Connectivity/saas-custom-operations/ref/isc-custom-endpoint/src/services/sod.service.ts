import { SailPointClient } from '../api/sailpoint.client.js';
import type {
  SodPolicy, 
  EntitlementRef, 
  DetectedViolation 
} from '../api/api.types.js';

export class SodService {
  constructor(private client: SailPointClient) {}

  /**
   * Holt alle aktiven SoD-Richtlinien (Segregation of Duties) von der SailPoint API.
   * Nutzt den neuen, service-basierten Pfad: /sod-policies/v3
   */
  async fetchSodPolicies(): Promise<SodPolicy[]> {
    try {
      // Das Limit setzen wir standardmäßig hoch (z.B. 250), um möglichst alle Policies in einem Rutsch zu holen.
      // Für extrem große Umgebungen müsste hier ein Pagination-Handling (offset) eingebaut werden.
      return await this.client.request<SodPolicy[]>(
        'sod-policies', 
        'v1', 
        '?limit=250&filters=state eq "ENFORCED"'
      );
    } catch (e) {
      console.error('[SodService] Error fetching SoD policies:', e);
      return [];
    }
  }

  /**
   * Gleicht eine Liste von Entitlements gegen die aktiven SoD-Richtlinien ab,
   * um potenzielle Konflikte zu identifizieren.
   * 
   * @param entitlements Die Gesamtmenge der Entitlements (bestehende + neu angeforderte).
   * @param policies Die Liste der zu prüfenden SoD-Richtlinien.
   */
  checkPoliciesAgainstEntitlements(
    entitlements: EntitlementRef[], 
    policies: SodPolicy[]
  ): DetectedViolation[] {
    const violations: DetectedViolation[] = [];
    const entitlementIds = new Set(entitlements.map(e => e.id));

    for (const policy of policies) {
      const criteria = policy.conflictingAccessCriteria;
      if (!criteria) continue;

      const leftIds = criteria.leftCriteria.criteriaList.map(c => c.id);
      const rightIds = criteria.rightCriteria.criteriaList.map(c => c.id);

      // Ermittle, welche Entitlements des Benutzers auf der "linken" Seite der Richtlinie liegen
      const matchedLeft = leftIds.filter(id => entitlementIds.has(id));
      // Ermittle, welche Entitlements des Benutzers auf der "rechten" Seite der Richtlinie liegen
      const matchedRight = rightIds.filter(id => entitlementIds.has(id));

      // Ein Verstoß liegt vor, wenn mindestens ein Item von der linken UND der rechten Seite vorhanden ist
      if (matchedLeft.length > 0 && matchedRight.length > 0) {
        violations.push({
          policyId: policy.id,
          policyName: policy.name,
          matchedLeft,
          matchedRight
        });
      }
    }

    return violations;
  }

    /**
   * Ruft die offizielle SailPoint SoD-Vorhersage für eine Identität und deren geplante Rechte ab.
   * Nutzt den Pfad: /sod-violations/v1/predict
   */
  async predictSodViolations(identityId: string, accessRefs: { id: string; type: 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE' }[]): Promise<any> {
    try {
      const payload = {
        identityId,
        accessRefs
      };
      
      return await this.client.request<any>(
        'sod-violations',
        'v1',
        '/predict',
        {
          method: 'POST',
          body: JSON.stringify(payload)
        }
      );
    } catch (e) {
      console.error(`[SodService] Error predicting SoD violations for identity ${identityId}:`, e);
      return null;
    }
  }

}