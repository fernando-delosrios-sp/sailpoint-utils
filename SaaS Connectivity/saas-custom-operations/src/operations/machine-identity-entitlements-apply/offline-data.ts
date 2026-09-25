import { MachineIdentityRecord } from '../../isc/machine-identities'

/** Canned machine identities for offline apply invokes: one empty, one already holding a ref. */
export const OFFLINE_APPLY_MACHINE_IDENTITIES: MachineIdentityRecord[] = [
    { id: 'mi-apply-empty', userEntitlements: [] },
    {
        id: 'mi-apply-existing',
        userEntitlements: [{ sourceId: 'src-offline-1', entitlementId: 'ent-offline-assigned' }],
    },
]

export function getMachineIdentityOffline(id: string): MachineIdentityRecord | undefined {
    return OFFLINE_APPLY_MACHINE_IDENTITIES.find((identity) => identity.id === id)
}
