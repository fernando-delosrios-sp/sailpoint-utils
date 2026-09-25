import { EntitlementRef } from './types'

/** Canned catalog entitlements for offline machine-identity evaluation. */
export const OFFLINE_ENTITLEMENTS: EntitlementRef[] = [
    { id: 'ent-offline-1', sourceId: 'src-offline-1', value: 'CN=Admins' },
    { id: 'ent-offline-2', sourceId: 'src-offline-1', value: 'CN=A' },
    { id: 'ent-offline-3', sourceId: 'src-offline-2', value: 'CN=B' },
    { id: 'ent-offline-assigned', sourceId: 'src-offline-1', value: 'CN=Already' },
]

/** Returns catalog entitlements whose value equals the caller-supplied string. */
export function listEntitlementsByValueOffline(value: string): EntitlementRef[] {
    return OFFLINE_ENTITLEMENTS.filter((entitlement) => entitlement.value === value)
}
