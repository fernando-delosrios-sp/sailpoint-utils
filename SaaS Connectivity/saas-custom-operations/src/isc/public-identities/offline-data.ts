/** Canned recipient emails for offline invokes without ISC credentials. */
export const OFFLINE_RECIPIENT_EMAILS: Record<string, string> = {
    'offline-owner': 'offline-owner@example.com',
}

/** Returns a deterministic offline recipient email for known identity IDs. */
export function resolveIdentityEmailOffline(identityId: string): string {
    return OFFLINE_RECIPIENT_EMAILS[identityId] ?? `${identityId}@offline.example.com`
}
