import { SailPointClient } from '../api/sailpoint.client.js';
import type { AccessRequestStatusPayload, EntitlementRef, RoleDetail, EntitlementDetail } from '../api/api.types.js';

export class AccessService {
  constructor(private client: SailPointClient) {}
  
  /**
   * Holt ausschließlich die Metadaten des direkt beantragten Items (Rolle, Profil oder Entitlement),
   * um daraus z.B. das iscRisk zu ermitteln.
   */
  async getRequestedItemMetadata(id: string, type: 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE'): Promise<any | null> {
    try {
      let detailObject: any = null;
      
      if (type === 'ROLE') {
        detailObject = await this.client.request<any>('roles', 'v1', `/${id}`);
      } else if (type === 'ACCESS_PROFILE') {
        detailObject = await this.client.request<any>('access-profiles', 'v1', `/${id}`);
      } else if (type === 'ENTITLEMENT') {
        detailObject = await this.client.request<any>('entitlements', 'v2', `/${id}`);
      }
      
      return detailObject?.accessModelMetadata || null;
    } catch (e) {
      console.error(`[AccessService] Error fetching metadata for ${type} ${id}:`, e);
      return null;
    }
  }


  /**
   * Extrahiert die zugrunde liegenden Entitlements für eine Zugriffsanfrage,
   * indem die vollständigen Details über die API abgerufen werden.
   */
  async getUnderlyingEntitlements(payload: AccessRequestStatusPayload): Promise<EntitlementRef[]> {
    const status = payload.getAccessRequestStatus;
    
    if (!status || !status.type || !status.id) {
      console.warn("[AccessService] Payload contains insufficient type or ID in 'getAccessRequestStatus'.");
      return [];
    }

    const requestedItemId = status.id; 

    switch (status.type) {
      case 'ENTITLEMENT':
        return this.resolveEntitlement(requestedItemId);
      case 'ACCESS_PROFILE':
        return this.resolveAccessProfile(requestedItemId);
      case 'ROLE':
        return this.resolveRole(requestedItemId);
      default:
        console.warn(`[AccessService] Unknown requested type: ${status.type}`);
        return [];
    }
  }

  /**
   * Ruft alle Entitlements ab, die aus anderen, parallel laufenden Anträgen ("EXECUTING") stammen.
   */
  async getPendingEntitlements(identityId: string, currentAccessRequestId: string): Promise<EntitlementRef[]> {
    if (!identityId) {
      return [];
    }

    try {
      const openRequests = await this.client.request<any[]>('access-request-status', 'v1', `?request-state=EXECUTING&requested-for=${identityId}`);

      if (!openRequests || !Array.isArray(openRequests)) {
        return [];
      }

      const otherPendingRequests = openRequests.filter(item => item.accessRequestId !== currentAccessRequestId);

      if (otherPendingRequests.length === 0) {
        return [];
      }

      const entitlementPromises = otherPendingRequests.map(item => {
        switch (item.type) {
          case 'ENTITLEMENT':
            return this.resolveEntitlement(item.id);
          case 'ACCESS_PROFILE':
            return this.resolveAccessProfile(item.id);
          case 'ROLE':
            return this.resolveRole(item.id);
          default:
            return Promise.resolve([]);
        }
      });
      
      const entitlementLists = await Promise.all(entitlementPromises);
      return this.deduplicateEntitlements(entitlementLists.flat());
    } catch (e) {
      console.error(`[AccessService] Error fetching pending access for identity ${identityId}:`, e);
      return [];
    }
  }

  /**
   * Ruft die bereits genehmigten und zugewiesenen Entitlements einer Identität ab
   * und löst diese vollständig (inklusive Source) auf.
   */
  async getGrantedEntitlements(identityId: string): Promise<EntitlementRef[]> {
    if (!identityId) {
      return [];
    }

    try {
      const grantedItems = await this.client.request<any[]>('entitlements', 'v1', `/identities/${identityId}/entitlements`);

      if (!grantedItems || !Array.isArray(grantedItems) || grantedItems.length === 0) {
        return [];
      }

      const entitlementPromises = grantedItems.map(item => this.resolveEntitlement(item.id));
      const resolvedEntitlementsLists = await Promise.all(entitlementPromises);
      const flattenedEntitlements = resolvedEntitlementsLists.flat();
      
      return this.deduplicateEntitlements(flattenedEntitlements);
    } catch (e) {
      console.error(`[AccessService] Error fetching granted entitlements for identity ${identityId}:`, e);
      return [];
    }
  }

  // --- Private Helper-Methoden zur Auflösung ---

  private async resolveEntitlement(id: string): Promise<EntitlementRef[]> {
    try {
      const detail = await this.client.request<EntitlementDetail>('entitlements', 'v2', `/${id}`);
      
      const entitlement: EntitlementRef = {
        type: 'ENTITLEMENT' as const,
        id: detail.id,
        ...(detail.name !== undefined && { name: detail.name }),
        ...(detail.source?.id && { 
            source: {
                id: detail.source.id,
                ...(detail.source.name !== undefined && { name: detail.source.name })
            }
        })
      };
      return [entitlement];
    } catch (e) {
      console.error(`[AccessService] Error resolving entitlement ${id}:`, e);
      return [];
    }
  }

  private async resolveAccessProfile(id: string): Promise<EntitlementRef[]> {
    try {
      const entitlementsRaw = await this.client.request<any[]>('access-profiles', 'v1', `/${id}/entitlements`);
      if (!entitlementsRaw || !Array.isArray(entitlementsRaw)) return [];

      return entitlementsRaw.map(item => ({
        type: 'ENTITLEMENT' as const,
        id: item.id,
        name: item.name,
        ...(item.source?.id && {
          source: {
            id: item.source.id,
            name: item.source.name,
          }
        })
      }));
    } catch (e) {
      console.error(`[AccessService] Error resolving access profile ${id}:`, e);
      return [];
    }
  }

  private async resolveRole(id: string): Promise<EntitlementRef[]> {
    try {
      const [detail, directEntitlementsRaw] = await Promise.all([
        this.client.request<RoleDetail>('roles', 'v1', `/${id}`),
        this.client.request<any[]>('roles', 'v1', `/${id}/entitlements`)
      ]);
      
      const allEntitlements: EntitlementRef[] = [];

      if (directEntitlementsRaw && Array.isArray(directEntitlementsRaw)) {
        const mappedDirect = directEntitlementsRaw.map(item => ({
          type: 'ENTITLEMENT' as const,
          id: item.id,
          name: item.name,
          ...(item.source?.id && {
            source: {
              id: item.source.id,
              name: item.source.name
            }
          })
        }));
        allEntitlements.push(...mappedDirect);
      }
      
      if (detail.accessProfiles && detail.accessProfiles.length > 0) {
          const profilePromises = detail.accessProfiles.map(ap => this.resolveAccessProfile(ap.id));
          const profileEntitlements = await Promise.all(profilePromises);
          allEntitlements.push(...profileEntitlements.flat());
      }
      
      return this.deduplicateEntitlements(allEntitlements);
    } catch (e) {
      console.error(`[AccessService] Error resolving role ${id}:`, e);
      return [];
    }
  }

  private deduplicateEntitlements(entitlements: EntitlementRef[]): EntitlementRef[] {
    const map = new Map<string, EntitlementRef>();
    for (const ent of entitlements) {
      if (ent && ent.id) { // Sicherheitsprüfung
        map.set(ent.id, ent);
      }
    }
    return Array.from(map.values());
  }
}
