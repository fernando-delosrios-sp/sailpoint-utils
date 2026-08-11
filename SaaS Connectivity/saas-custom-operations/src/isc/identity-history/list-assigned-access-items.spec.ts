import { describe, expect, it, vi } from 'vitest'
import { listAssignedAccessItems } from './list-assigned-access-items'

describe('isc/identity-history', () => {
    it('listAssignedAccessItems calls listIdentityAccessItemsV1 with experimental flag for access profiles', async () => {
        const listIdentityAccessItemsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ap-1', displayName: 'Finance AP' }],
        })

        const items = await listAssignedAccessItems(
            { listIdentityAccessItemsV1 } as never,
            'ident-1',
            'accessProfile'
        )

        expect(listIdentityAccessItemsV1).toHaveBeenCalledWith({
            id: 'ident-1',
            type: 'accessProfile',
            xSailPointExperimental: 'true',
        })
        expect(items).toEqual([{ id: 'ap-1', displayName: 'Finance AP' }])
    })

    it('listAssignedAccessItems calls listIdentityAccessItemsV1 with type role', async () => {
        const listIdentityAccessItemsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'role-1', displayName: 'Finance Role' }],
        })

        const items = await listAssignedAccessItems({ listIdentityAccessItemsV1 } as never, 'ident-1', 'role')

        expect(listIdentityAccessItemsV1).toHaveBeenCalledWith({
            id: 'ident-1',
            type: 'role',
            xSailPointExperimental: 'true',
        })
        expect(items).toEqual([{ id: 'role-1', displayName: 'Finance Role' }])
    })
})

