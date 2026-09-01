import { describe, expect, it, vi } from 'vitest'
import { fetchIdentityAccessItemsFromSdk, fetchIdentityAccessItemsOffline } from './index'

describe('isc/identity-access', () => {
    it('SDK loopback listing lists roles only and does not call access profiles', async () => {
        const listIdentityAccessItemsV1 = vi
            .fn()
            .mockImplementation(async ({ type }: { type?: string }) => {
                if (type === 'accessProfile') {
                    return { data: [{ id: 'ap-1', displayName: 'Finance AP' }] }
                }
                if (type === 'role') {
                    return { data: [{ id: 'role-1', displayName: 'Finance Role' }] }
                }
                return { data: [] }
            })
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-1' }, { id: 'ent-2' }],
        })
        const getRoleEntitlementsV1 = vi.fn().mockResolvedValue({ data: [{ id: 'ent-1' }] })

        const items = await fetchIdentityAccessItemsFromSdk(
            {
                identityHistory: { listIdentityAccessItemsV1 } as never,
                roles: { getRoleEntitlementsV1 } as never,
            },
            'ident-1'
        )

        expect(listIdentityAccessItemsV1).toHaveBeenCalledTimes(1)
        expect(listIdentityAccessItemsV1).toHaveBeenCalledWith(
            expect.objectContaining({ id: 'ident-1', type: 'role', xSailPointExperimental: 'true' })
        )
        expect(listIdentityAccessItemsV1).not.toHaveBeenCalledWith(
            expect.objectContaining({ type: 'accessProfile' })
        )
        expect(getAccessProfileEntitlementsV1).not.toHaveBeenCalled()
        expect(getRoleEntitlementsV1).toHaveBeenCalledWith({ id: 'role-1' })
        expect(items).toEqual([
            {
                type: 'ROLE',
                id: 'role-1',
                name: 'Finance Role',
                grantedEntitlementIds: ['ent-1'],
            },
        ])
        expect(items.some((item) => item.type === 'ACCESS_PROFILE')).toBe(false)
    })

    it('Offline data listing returns a role, not an access profile', async () => {
        const items = await fetchIdentityAccessItemsOffline('offline-identity')

        expect(items.some((item) => item.type === 'ACCESS_PROFILE')).toBe(false)
        expect(items).toEqual([
            {
                type: 'ROLE',
                id: 'offline-role-a',
                name: 'Offline Finance Role',
                grantedEntitlementIds: ['offline-ent-a'],
            },
        ])
    })

    it('fetchIdentityAccessItemsOffline returns empty list for unknown identities', async () => {
        await expect(fetchIdentityAccessItemsOffline('unknown-identity')).resolves.toEqual([])
    })
})
