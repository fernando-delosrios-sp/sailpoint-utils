import { MachineIdentityRecord } from './types'

/** Canned machine identities for offline invokes (id and cisIdentityId shapes). */
export const OFFLINE_MACHINE_IDENTITIES: MachineIdentityRecord[] = [
    {
        id: 'mi-offline-1',
        cisIdentityId: 'cis-offline-1',
        userEntitlements: [],
    },
    {
        id: 'mi-offline-2',
        cisIdentityId: 'cis-offline-2',
        userEntitlements: [{ sourceId: 'src-offline-1', entitlementId: 'ent-offline-assigned' }],
    },
]

/** Lists canned machine identities, optionally filtered by id or cisIdentityId. */
export function listMachineIdentitiesOffline(identityId?: string): MachineIdentityRecord[] {
    if (!identityId) {
        return OFFLINE_MACHINE_IDENTITIES
    }
    const match = resolveMachineIdentityByIdentityIdOffline(identityId)
    return match ? [match] : []
}

/** Resolves a canned machine identity by id then cisIdentityId. */
export function resolveMachineIdentityByIdentityIdOffline(identityId: string): MachineIdentityRecord | undefined {
    return (
        OFFLINE_MACHINE_IDENTITIES.find((identity) => identity.id === identityId) ??
        OFFLINE_MACHINE_IDENTITIES.find((identity) => identity.cisIdentityId === identityId)
    )
}

/** Returns a canned machine identity including userEntitlements. */
export function getMachineIdentityOffline(id: string): MachineIdentityRecord | undefined {
    return OFFLINE_MACHINE_IDENTITIES.find((identity) => identity.id === id)
}
