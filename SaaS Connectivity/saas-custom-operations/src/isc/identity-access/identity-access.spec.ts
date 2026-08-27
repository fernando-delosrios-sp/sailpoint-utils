import { describe, expect, it, vi } from 'vitest'
import { fetchIdentityAccessItemsFromSdk, fetchIdentityAccessItemsOffline } from './index'

describe('isc/identity-access', () => {
    it('fetchIdentityAccessItemsFromSdk maps access profiles and roles with granted entitlement IDs', async () => {
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
                accessProfiles: { getAccessProfileEntitlementsV1 } as never,
                roles: { getRoleEntitlementsV1 } as never,
            },
            'ident-1'
        )

        expect(listIdentityAccessItemsV1).toHaveBeenCalledWith(
            expect.objectContaining({ id: 'ident-1', type: 'accessProfile', xSailPointExperimental: 'true' })
        )
        expect(listIdentityAccessItemsV1).toHaveBeenCalledWith(
            expect.objectContaining({ id: 'ident-1', type: 'role', xSailPointExperimental: 'true' })
        )
        expect(getAccessProfileEntitlementsV1).toHaveBeenCalledWith({ id: 'ap-1' })
        expect(getRoleEntitlementsV1).toHaveBeenCalledWith({ id: 'role-1' })
        expect(items).toEqual([
            {
                type: 'ACCESS_PROFILE',
                id: 'ap-1',
                name: 'Finance AP',
                grantedEntitlementIds: ['ent-1', 'ent-2'],
            },
            {
                type: 'ROLE',
                id: 'role-1',
                name: 'Finance Role',
                grantedEntitlementIds: ['ent-1'],
            },
        ])
    })

    it('fetchIdentityAccessItemsOffline returns deterministic offline data for known offline identities', async () => {
        await expect(fetchIdentityAccessItemsOffline('offline-identity')).resolves.toEqual([
            {
                type: 'ACCESS_PROFILE',
                id: 'offline-ap-a',
                name: 'Offline Finance AP',
                grantedEntitlementIds: ['offline-ent-a'],
            },
        ])
    })

    it('fetchIdentityAccessItemsOffline returns empty list for unknown identities', async () => {
        await expect(fetchIdentityAccessItemsOffline('unknown-identity')).resolves.toEqual([])
    })
})
