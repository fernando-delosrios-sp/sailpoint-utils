import { EventSearchDocument } from './types'

export const OFFLINE_EVENTS_BY_TRACKING: Record<string, EventSearchDocument[]> = {
    'offline-tracking-001': [
        {
            attributes: {
                accessItemId: 'offline-role-001',
                accessItemName: 'Offline Analyst Role',
                accessItemType: 'Role',
            },
        },
    ],
}

/** Returns deterministic offline event documents for a tracking number. */
export function searchEventsByTrackingNumberOffline(trackingNumber: string): EventSearchDocument[] {
    return OFFLINE_EVENTS_BY_TRACKING[trackingNumber] ?? []
}
