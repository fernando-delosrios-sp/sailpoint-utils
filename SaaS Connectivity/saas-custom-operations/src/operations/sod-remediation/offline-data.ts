import { ViolationV1 } from '../../isc/violations'

/** Canned violation for offline invokes without ISC credentials. */
export const OFFLINE_VIOLATION: ViolationV1 = {
    id: 'offline-violation',
    owner: { id: 'offline-owner', name: 'Offline Owner' },
    identity: { id: 'offline-identity', name: 'Offline User' },
    policy: { id: 'offline-policy', name: 'Offline SOD Policy' },
    leftSide: { entitlements: [{ id: 'offline-ent-a', name: 'Offline Entitlement A' }] },
    rightSide: { entitlements: [{ id: 'offline-ent-b', name: 'Offline Entitlement B' }] },
}
