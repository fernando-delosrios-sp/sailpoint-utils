import { Buffer } from 'buffer';

/**
 * Entschlüsselt den JWT aus dem Authorization-Header, um die API-Base-URL des Tenants zu ermitteln.
 * @param token Der rohe Bearer JWT.
 * @returns Die Base URL (z.B. 'https://tenant.api.identitynow.com') oder null.
 */
export function getApiBaseUrlFromToken(token: string): string | null {
  try {
    const parts = token.split('.');
    // Ein valider JWT hat mindestens Header, Payload und Signatur (3 Teile)
    if (parts.length < 3) return null;
    
    const headerB64 = parts[0];
    if (!headerB64) return null;

    const headerJson = Buffer.from(headerB64, 'base64url').toString('utf-8');
    const header = JSON.parse(headerJson) as { jku?: string };
    
    if (!header.jku) return null;

    const jkuUrl = new URL(header.jku);
    return `${jkuUrl.protocol}//${jkuUrl.host}`;
  } catch (e) {
    console.error('Fehler beim Extrahieren der API Base URL aus dem Token:', e);
    return null;
  }
}
