import { beforeEach, describe, expect, it, vi } from 'vitest'
import { resolveCatalogAccessItemOwnerId } from './resolve-catalog-access-item-owner'

describe('resolveCatalogAccessItemOwnerId', () => {
    const getRoleV1 = vi.fn()
    const getAccessProfileV1 = vi.fn()
    const clients = {
        roles: { getRoleV1 },
        accessProfiles: { getAccessProfileV1 },
    }

    beforeEach(() => {
        getRoleV1.mockReset()
        getAccessProfileV1.mockReset()
    })

    it('fetches role owner via getRoleV1', async () => {
        getRoleV1.mockResolvedValue({ data: { owner: { type: 'IDENTITY', id: 'item-owner-1' } } })

        await expect(
            resolveCatalogAccessItemOwnerId(clients as never, {
                id: 'role-r',
                name: 'Finance',
                type: 'ROLE',
            })
        ).resolves.toBe('item-owner-1')

        expect(getRoleV1).toHaveBeenCalledWith({ id: 'role-r' })
        expect(getAccessProfileV1).not.toHaveBeenCalled()
    })

    it('fetches access profile owner via getAccessProfileV1', async () => {
        getAccessProfileV1.mockResolvedValue({ data: { owner: { id: 'item-owner-2' } } })

        await expect(
            resolveCatalogAccessItemOwnerId(clients as never, {
                id: 'ap-v',
                name: 'SAP',
                type: 'ACCESS_PROFILE',
            })
        ).resolves.toBe('item-owner-2')

        expect(getAccessProfileV1).toHaveBeenCalledWith({ id: 'ap-v' })
        expect(getRoleV1).not.toHaveBeenCalled()
    })

    it('Missing role owner fails after fetch', async () => {
        getRoleV1.mockResolvedValue({ data: { owner: undefined } })

        await expect(
            resolveCatalogAccessItemOwnerId(clients as never, {
                id: 'role-r',
                name: 'Finance',
                type: 'ROLE',
            })
        ).rejects.toThrow(/Role role-r has no owner.id/)
    })
})
