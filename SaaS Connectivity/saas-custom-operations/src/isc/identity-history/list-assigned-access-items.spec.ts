import { describe, expect, it, vi } from 'vitest'
import { listAssignedAccessItems } from './list-assigned-access-items'

describe('isc/identity-history', () => {
    it('listAssignedAccessItems calls listIdentityAccessItemsV1 with experimental flag', async () => {
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
})
