import type { IdentityWithSunsetAccessProfiles } from './types'

/** Builds an ISO removeDate `daysFromNow` calendar days from `now` (UTC noon). */
export function buildOfflineRemoveDate(daysFromNow: number, now: Date = new Date()): string {
    const date = new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + daysFromNow, 12, 0, 0)
    )
    return date.toISOString()
}

/**
 * Offline fixtures for sunset ACCESS_PROFILE search.
 * `identity-offline-1` has manager `mgr-offline-1` and an ACCESS_PROFILE with removeDate = tomorrow UTC
 * relative to {@link OFFLINE_REFERENCE_NOW}. Use fake timers or match against that reference in tests.
 */
export const OFFLINE_REFERENCE_NOW = new Date('2026-08-19T12:00:00.000Z')

export const OFFLINE_SUNSET_IDENTITIES: IdentityWithSunsetAccessProfiles[] = [
    {
        id: 'identity-offline-1',
        displayName: 'Offline User One',
        managerId: 'mgr-offline-1',
        accessProfiles: [
            {
                id: 'ap-offline-1',
                name: 'SAP Suite',
                removeDate: buildOfflineRemoveDate(1, OFFLINE_REFERENCE_NOW),
                sourceName: 'SAP',
            },
        ],
    },
    {
        id: 'identity-offline-no-manager',
        displayName: 'Offline User No Manager',
        accessProfiles: [
            {
                id: 'ap-offline-2',
                name: 'Finance AP',
                removeDate: buildOfflineRemoveDate(1, OFFLINE_REFERENCE_NOW),
                sourceName: 'Finance',
            },
        ],
    },
]

/** Returns deterministic offline identities with sunset ACCESS_PROFILE assignments. */
export function searchIdentitiesWithSunsetAccessProfilesOffline(): IdentityWithSunsetAccessProfiles[] {
    return OFFLINE_SUNSET_IDENTITIES
}
