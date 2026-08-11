import { describe, expect, it, vi } from 'vitest'
import { listRoleEntitlementIds } from './role-entitlements'

describe('isc/roles', () => {
    it('listRoleEntitlementIds returns entitlement ids from getRoleEntitlementsV1', async () => {
        const getRoleEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-1' }],
        })

        const ids = await listRoleEntitlementIds({ getRoleEntitlementsV1 } as never, 'role-1')

        expect(getRoleEntitlementsV1).toHaveBeenCalledWith({ id: 'role-1' })
        expect(ids).toEqual(['ent-1'])
    })
})
