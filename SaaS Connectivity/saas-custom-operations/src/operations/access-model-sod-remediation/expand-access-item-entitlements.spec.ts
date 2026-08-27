import { describe, expect, it, vi } from 'vitest'
import { expandAccessItemEntitlements } from './expand-access-item-entitlements'

describe('expandAccessItemEntitlements', () => {
    it('expands standalone access profile to flat entitlement ids', async () => {
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [
                { id: 'ent-1', name: 'Entitlement One' },
                { id: 'ent-2', name: 'Entitlement Two' },
            ],
        })
        const clients = {
            roles: {},
            accessProfiles: { getAccessProfileEntitlementsV1 },
        } as never

        const result = await expandAccessItemEntitlements(clients, {
            id: 'ap-1',
            name: 'Finance AP',
            type: 'ACCESS_PROFILE',
        })

        expect(getAccessProfileEntitlementsV1).toHaveBeenCalledWith({ id: 'ap-1' })
        expect([...result.entitlementIds]).toEqual(['ent-1', 'ent-2'])
        expect(result.entitlements).toEqual([
            { id: 'ent-1', name: 'Entitlement One' },
            { id: 'ent-2', name: 'Entitlement Two' },
        ])
        expect(result.nestedProfiles).toEqual([])
    })

    it('expands role with direct entitlements and nested access profiles', async () => {
        const getRoleEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-direct', name: 'Direct Ent' }],
        })
        const getRoleV1 = vi.fn().mockResolvedValue({
            data: {
                accessProfiles: [{ id: 'nested-ap-1', name: 'Nested AP' }],
            },
        })
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-nested', name: 'Nested Ent' }],
        })
        const clients = {
            roles: { getRoleEntitlementsV1, getRoleV1 },
            accessProfiles: { getAccessProfileEntitlementsV1 },
        } as never

        const result = await expandAccessItemEntitlements(clients, {
            id: 'role-1',
            name: 'Finance Role',
            type: 'ROLE',
        })

        expect(getRoleEntitlementsV1).toHaveBeenCalledWith({ id: 'role-1' })
        expect(getRoleV1).toHaveBeenCalledWith({ id: 'role-1' })
        expect(getAccessProfileEntitlementsV1).toHaveBeenCalledWith({ id: 'nested-ap-1' })
        expect([...result.entitlementIds]).toEqual(['ent-direct', 'ent-nested'])
        expect(result.nestedProfiles).toEqual([
            {
                id: 'nested-ap-1',
                name: 'Nested AP',
                entitlements: [{ id: 'ent-nested', name: 'Nested Ent' }],
            },
        ])
    })

    it('deduplicates entitlement ids shared between direct role and nested access profile', async () => {
        const getRoleEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-shared' }],
        })
        const getRoleV1 = vi.fn().mockResolvedValue({
            data: {
                accessProfiles: [{ id: 'nested-ap-1', name: 'Nested AP' }],
            },
        })
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-shared', name: 'Shared Ent' }],
        })
        const clients = {
            roles: { getRoleEntitlementsV1, getRoleV1 },
            accessProfiles: { getAccessProfileEntitlementsV1 },
        } as never

        const result = await expandAccessItemEntitlements(clients, {
            id: 'role-1',
            name: 'Finance Role',
            type: 'ROLE',
        })

        expect([...result.entitlementIds]).toEqual(['ent-shared'])
        expect(result.entitlements).toEqual([{ id: 'ent-shared', name: 'Shared Ent' }])
    })

    it('preserves entitlement name when duplicate id appears without name later', async () => {
        const getRoleEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-shared', name: 'Shared Ent' }],
        })
        const getRoleV1 = vi.fn().mockResolvedValue({
            data: {
                accessProfiles: [{ id: 'nested-ap-1', name: 'Nested AP' }],
            },
        })
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-shared' }],
        })
        const clients = {
            roles: { getRoleEntitlementsV1, getRoleV1 },
            accessProfiles: { getAccessProfileEntitlementsV1 },
        } as never

        const result = await expandAccessItemEntitlements(clients, {
            id: 'role-1',
            name: 'Finance Role',
            type: 'ROLE',
        })

        expect(result.entitlements).toEqual([{ id: 'ent-shared', name: 'Shared Ent' }])
    })
})
