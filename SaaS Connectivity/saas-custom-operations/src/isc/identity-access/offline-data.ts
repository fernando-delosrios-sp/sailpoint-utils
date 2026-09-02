import type { IdentityAccessItem } from './types'

/** Deterministic access items for offline SOD remediation and local operation invokes. */
const OFFLINE_IDENTITY_ACCESS_DATA: Record<string, IdentityAccessItem[]> = {
    'offline-identity': [
        {
            type: 'ROLE',
            id: 'offline-role-a',
            name: 'Offline Finance Role',
            grantedEntitlementIds: ['offline-ent-a'],
        },
    ],
}

/** Offline fallback when ISC credentials are unavailable. */
export async function fetchIdentityAccessItemsOffline(identityId: string): Promise<IdentityAccessItem[]> {
    return OFFLINE_IDENTITY_ACCESS_DATA[identityId] ?? []
}
