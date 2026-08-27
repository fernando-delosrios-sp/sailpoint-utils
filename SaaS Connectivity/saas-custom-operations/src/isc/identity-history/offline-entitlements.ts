export interface AssignedEntitlementItem {
    id: string
    displayName: string
    privileged: boolean
}

/** Canned entitlement assignments for offline SOD remediation invokes. */
export function listAssignedEntitlementsOffline(identityId: string): AssignedEntitlementItem[] {
    if (identityId !== 'offline-identity') {
        return []
    }

    return [
        {
            id: 'offline-ent-a',
            displayName: 'Offline Entitlement A',
            privileged: true,
        },
        {
            id: 'offline-ent-b',
            displayName: 'Offline Entitlement B',
            privileged: false,
        },
    ]
}
