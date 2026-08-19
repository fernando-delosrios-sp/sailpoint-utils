import { describe, expect, it, vi } from 'vitest'
import { SearchApi } from 'sailpoint-api-client'
import {
    OFFLINE_REFERENCE_NOW,
    OFFLINE_SUNSET_IDENTITIES,
    buildOfflineRemoveDate,
    extractManagerId,
    searchIdentitiesWithSunsetAccessProfiles,
    searchIdentitiesWithSunsetAccessProfilesOffline,
} from './index'

describe('isc/identities sunset search', () => {
    it('maps sunset ACCESS_PROFILE assignments and manager id from search hits', async () => {
        const searchPostV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    id: 'id-1',
                    displayName: 'Ada Lovelace',
                    name: 'ada',
                    manager: { id: 'mgr-1', type: 'IDENTITY' },
                    access: [
                        {
                            id: 'ap-1',
                            name: 'SAP Suite',
                            type: 'ACCESS_PROFILE',
                            removeDate: '2026-08-20T12:00:00.000Z',
                            source: { name: 'SAP' },
                        },
                        {
                            id: 'role-1',
                            name: 'Finance Role',
                            type: 'ROLE',
                            removeDate: '2026-08-20T12:00:00.000Z',
                        },
                        {
                            id: 'ap-no-remove',
                            name: 'No Sunset',
                            type: 'ACCESS_PROFILE',
                        },
                    ],
                },
            ],
        })

        const result = await searchIdentitiesWithSunsetAccessProfiles({ searchPostV1 } as unknown as SearchApi)

        expect(searchPostV1).toHaveBeenCalledWith({
            offset: 0,
            limit: 250,
            search: {
                indices: ['identities'],
                query: { query: '@access(type:ACCESS_PROFILE AND removeDate:*)' },
                includeNested: true,
            },
        })
        expect(result).toEqual([
            {
                id: 'id-1',
                displayName: 'Ada Lovelace',
                managerId: 'mgr-1',
                accessProfiles: [
                    {
                        id: 'ap-1',
                        name: 'SAP Suite',
                        removeDate: '2026-08-20T12:00:00.000Z',
                        sourceName: 'SAP',
                    },
                ],
            },
        ])
    })

    it('omits managerId when manager is absent', async () => {
        const searchPostV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    id: 'id-2',
                    name: 'No Manager',
                    access: [
                        {
                            id: 'ap-2',
                            name: 'Finance AP',
                            type: 'ACCESS_PROFILE',
                            removeDate: '2026-08-21T00:00:00.000Z',
                        },
                    ],
                },
            ],
        })

        const result = await searchIdentitiesWithSunsetAccessProfiles({ searchPostV1 } as unknown as SearchApi)

        expect(result).toEqual([
            {
                id: 'id-2',
                displayName: 'No Manager',
                managerId: undefined,
                accessProfiles: [
                    {
                        id: 'ap-2',
                        name: 'Finance AP',
                        removeDate: '2026-08-21T00:00:00.000Z',
                        sourceName: undefined,
                    },
                ],
            },
        ])
    })

    it('paginates search results until a short page', async () => {
        const page = Array.from({ length: 250 }, (_, i) => ({
            id: `id-${i}`,
            name: `User ${i}`,
            access: [
                {
                    id: `ap-${i}`,
                    name: `AP ${i}`,
                    type: 'ACCESS_PROFILE',
                    removeDate: '2026-08-20T12:00:00.000Z',
                },
            ],
        }))
        const searchPostV1 = vi
            .fn()
            .mockResolvedValueOnce({ data: page })
            .mockResolvedValueOnce({
                data: [
                    {
                        id: 'id-last',
                        name: 'Last',
                        access: [
                            {
                                id: 'ap-last',
                                name: 'Last AP',
                                type: 'ACCESS_PROFILE',
                                removeDate: '2026-08-20T12:00:00.000Z',
                            },
                        ],
                    },
                ],
            })

        const result = await searchIdentitiesWithSunsetAccessProfiles({ searchPostV1 } as unknown as SearchApi)

        expect(searchPostV1).toHaveBeenCalledTimes(2)
        expect(searchPostV1).toHaveBeenNthCalledWith(
            2,
            expect.objectContaining({ offset: 250, limit: 250 })
        )
        expect(result).toHaveLength(251)
        expect(result[250]?.id).toBe('id-last')
    })
})

describe('extractManagerId', () => {
    it('reads manager.id when type is IDENTITY', () => {
        expect(extractManagerId({ manager: { id: 'mgr-1', type: 'IDENTITY' } })).toBe('mgr-1')
    })

    it('reads managerRef.id when manager is absent', () => {
        expect(extractManagerId({ managerRef: { id: 'mgr-ref-1' } })).toBe('mgr-ref-1')
    })

    it('returns undefined when manager is absent', () => {
        expect(extractManagerId({ id: 'id-1' })).toBeUndefined()
        expect(extractManagerId(null)).toBeUndefined()
    })
})

describe('offline sunset search', () => {
    it('returns fixtures without calling the search API', () => {
        const searchPostV1 = vi.fn()

        const result = searchIdentitiesWithSunsetAccessProfilesOffline()

        expect(searchPostV1).not.toHaveBeenCalled()
        expect(result).toEqual(OFFLINE_SUNSET_IDENTITIES)
        expect(result[0]?.managerId).toBe('mgr-offline-1')
        expect(result[0]?.accessProfiles[0]?.removeDate).toBe(buildOfflineRemoveDate(1, OFFLINE_REFERENCE_NOW))
        expect(result[1]?.managerId).toBeUndefined()
    })
})
