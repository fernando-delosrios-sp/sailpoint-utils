import { describe, expect, it, vi } from 'vitest'
import { SearchApi } from 'sailpoint-api-client'
import { listEnabledAccessProfiles } from './list-enabled-access-profiles'

describe('listEnabledAccessProfiles', () => {
    it('uses ISC search for wildcard scope', async () => {
        const searchPostV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ap-1', name: 'Enabled Profile' }],
        })

        const search = { searchPostV1 } as unknown as SearchApi
        const result = await listEnabledAccessProfiles({} as never, '*', search)

        expect(searchPostV1).toHaveBeenCalledWith({
            offset: 0,
            limit: 250,
            search: {
                indices: ['accessprofiles'],
                query: { query: 'enabled:true' },
            },
        })
        expect(result).toEqual([{ id: 'ap-1', name: 'Enabled Profile', type: 'ACCESS_PROFILE' }])
    })
})
