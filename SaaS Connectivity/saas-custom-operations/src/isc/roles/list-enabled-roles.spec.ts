import { describe, expect, it, vi } from 'vitest'
import { SearchApi } from 'sailpoint-api-client'
import { listEnabledRoles } from './list-enabled-roles'

describe('listEnabledRoles', () => {
    it('uses ISC search for wildcard scope', async () => {
        const searchPostV1 = vi
            .fn()
            .mockResolvedValueOnce({
                data: [{ id: 'role-1', name: 'Enabled Role' }],
            })
            .mockResolvedValueOnce({ data: [] })

        const search = { searchPostV1 } as unknown as SearchApi
        const result = await listEnabledRoles({} as never, '*', search)

        expect(searchPostV1).toHaveBeenCalledWith({
            offset: 0,
            limit: 250,
            search: {
                indices: ['roles'],
                query: { query: 'enabled:true' },
            },
        })
        expect(result).toEqual([{ id: 'role-1', name: 'Enabled Role', type: 'ROLE' }])
    })

    it('uses list API for V3 list filter scope and skips disabled roles', async () => {
        const listRolesV1 = vi
            .fn()
            .mockResolvedValueOnce({
                data: [
                    { id: 'role-1', name: 'Enabled Role', enabled: true },
                    { id: 'role-2', name: 'Disabled Role', enabled: false },
                ],
            })
            .mockResolvedValueOnce({ data: [] })

        const roles = { listRolesV1 } as unknown as Parameters<typeof listEnabledRoles>[0]
        const result = await listEnabledRoles(roles, 'name sw "Finance-"')

        expect(listRolesV1).toHaveBeenCalledWith({
            offset: 0,
            limit: 50,
            filters: 'name sw "Finance-"',
        })
        expect(result).toEqual([{ id: 'role-1', name: 'Enabled Role', type: 'ROLE' }])
    })
})
