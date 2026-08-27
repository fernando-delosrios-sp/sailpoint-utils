import { describe, expect, it, vi } from 'vitest'
import { extractAccessItemsFromEvents } from './extract-access-items'
import { searchEventsByTrackingNumber, searchEventsByTrackingNumberWithRetry } from './search-events'
import { searchEventsByTrackingNumberOffline } from './offline-data'

describe('isc/events-search', () => {
    it('searchEventsByTrackingNumber queries events index by tracking number', async () => {
        const searchPostV1 = vi.fn().mockResolvedValue({
            data: [{ attributes: { accessItemId: 'ent-1', accessItemType: 'Entitlement' } }],
        })

        const events = await searchEventsByTrackingNumber({ searchPostV1 } as never, 'track-123')

        expect(searchPostV1).toHaveBeenCalledWith({
            search: {
                indices: ['events'],
                query: {
                    query: 'trackingNumber:track-123 AND status:STARTED',
                },
                includeNested: true,
            },
        })
        expect(events).toHaveLength(1)
    })

    it('searchEventsByTrackingNumberWithRetry succeeds on second attempt', async () => {
        const searchPostV1 = vi
            .fn()
            .mockResolvedValueOnce({ data: [] })
            .mockResolvedValueOnce({
                data: [{ attributes: { accessItemId: 'ent-1', accessItemType: 'Entitlement' } }],
            })
        const sleep = vi.fn().mockResolvedValue(undefined)

        const events = await searchEventsByTrackingNumberWithRetry({ searchPostV1 } as never, 'track-123', {
            maxAttempts: 3,
            delayMs: 10,
            sleep,
        })

        expect(searchPostV1).toHaveBeenCalledTimes(2)
        expect(sleep).toHaveBeenCalledWith(10)
        expect(events).toHaveLength(1)
    })

    it('searchEventsByTrackingNumberWithRetry returns empty after max attempts without throw', async () => {
        const searchPostV1 = vi.fn().mockResolvedValue({ data: [] })
        const sleep = vi.fn().mockResolvedValue(undefined)

        const events = await searchEventsByTrackingNumberWithRetry({ searchPostV1 } as never, 'track-123', {
            maxAttempts: 2,
            delayMs: 1,
            sleep,
        })

        expect(searchPostV1).toHaveBeenCalledTimes(2)
        expect(events).toEqual([])
    })

    it('extractAccessItemsFromEvents dedupes ENTITLEMENT, ROLE, and ACCESS_PROFILE refs', () => {
        const items = extractAccessItemsFromEvents([
            { attributes: { accessItemId: 'ent-1', accessItemType: 'Entitlement', accessItemName: 'Ent 1' } },
            { attributes: { accessItemId: 'ent-1', accessItemType: 'Entitlement', accessItemName: 'Ent 1 dup' } },
            { attributes: { accessItemId: 'role-1', accessItemType: 'Role', accessItemName: 'Role 1' } },
            { attributes: { accessItemId: 'ap-1', accessItemType: 'AccessProfile', accessItemName: 'AP 1' } },
        ])

        expect(items).toEqual([
            { id: 'ent-1', type: 'ENTITLEMENT', name: 'Ent 1' },
            { id: 'role-1', type: 'ROLE', name: 'Role 1' },
            { id: 'ap-1', type: 'ACCESS_PROFILE', name: 'AP 1' },
        ])
    })

    it('searchEventsByTrackingNumberOffline returns canned events', () => {
        const events = searchEventsByTrackingNumberOffline('offline-tracking-001')

        expect(events).toHaveLength(1)
        expect(events[0]?.attributes?.accessItemId).toBe('offline-role-001')
    })
})
