import { MachineIdentityRecord, UserEntitlementRef } from './types'

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

function mapUserEntitlement(raw: unknown): UserEntitlementRef | undefined {
    if (!isRecord(raw)) {
        return undefined
    }
    const sourceId = typeof raw.sourceId === 'string' ? raw.sourceId : undefined
    const entitlementId = typeof raw.entitlementId === 'string' ? raw.entitlementId : undefined
    if (!sourceId || !entitlementId) {
        return undefined
    }
    return { sourceId, entitlementId }
}

/** Maps an ISC machine identity payload onto the isc wrapper record. */
export function mapMachineIdentity(raw: unknown): MachineIdentityRecord | undefined {
    if (!isRecord(raw) || typeof raw.id !== 'string' || !raw.id) {
        return undefined
    }

    const cisIdentityId = typeof raw.cisIdentityId === 'string' ? raw.cisIdentityId : undefined
    const userEntitlements = Array.isArray(raw.userEntitlements)
        ? raw.userEntitlements.map(mapUserEntitlement).filter((ref): ref is UserEntitlementRef => Boolean(ref))
        : []

    return {
        id: raw.id,
        ...(cisIdentityId ? { cisIdentityId } : {}),
        userEntitlements,
    }
}
