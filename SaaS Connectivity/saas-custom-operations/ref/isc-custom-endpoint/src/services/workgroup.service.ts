import { SailPointClient } from '../api/sailpoint.client.js';

export class WorkgroupService {
  constructor(private client: SailPointClient) {}

  /**
   * Sucht eine Workgroup (Governance Group) anhand ihres Namens und gibt die ID zurück.
   */
  async getWorkgroupIdByName(groupName: string): Promise<string | null> {
    try {
      // URL-Encoding für den Filter ist wichtig, da Leerzeichen im Namen vorkommen
      const filter = encodeURIComponent(`name eq "${groupName}"`);
      const response = await this.client.request<any[]>('workgroups', 'v1', `?filters=${filter}`);
      
      if (response && response.length > 0 && response[0].id) {
        return response[0].id;
      }
      return null;
    } catch (e) {
      console.error(`[WorkgroupService] Error fetching workgroup ID for name "${groupName}":`, e);
      return null;
    }
  }

  /**
   * Holt die Mitglieder einer Workgroup anhand der ID und gibt ein 
   * Array aller gefundenen E-Mail-Adressen zurück.
   */
  async getWorkgroupMembersEmails(workgroupId: string): Promise<string[]> {
    try {
      const members = await this.client.request<any[]>('workgroups', 'v1', `/${workgroupId}/members`);
      
      if (!members || !Array.isArray(members)) {
        return [];
      }

      // Mappt alle Mitglieder auf ihre E-Mail (falls vorhanden) und filtert leere Werte heraus
      const emails = members
        .map(member => member.email)
        .filter(email => email && email.trim() !== '');

      // Gib direkt das Array zurück (ohne .join(', '))
      return emails;
    } catch (e) {
      console.error(`[WorkgroupService] Error fetching members for workgroup ID ${workgroupId}:`, e);
      return [];
    }
  }

}
