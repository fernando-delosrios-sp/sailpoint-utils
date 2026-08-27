import { describe, expect, it, vi } from 'vitest'
import { listAccessProfileEntitlementIds } from './access-profile-entitlements'

describe('isc/access-profiles', () => {
    it('listAccessProfileEntitlementIds returns entitlement ids from getAccessProfileEntitlementsV1', async () => {
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-1' }, { id: 'ent-2' }, {}],
        })

        const ids = await listAccessProfileEntitlementIds(
            { getAccessProfileEntitlementsV1 } as never,
            'ap-1'
        )

        expect(getAccessProfileEntitlementsV1).toHaveBeenCalledWith({ id: 'ap-1' })
        expect(ids).toEqual(['ent-1', 'ent-2'])
    })

    it('listAccessProfileEntitlements preserves entitlement names', async () => {
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-1', name: 'Finance Admin' }],
        })

        const { listAccessProfileEntitlements } = await import('./access-profile-entitlements')
        const entitlements = await listAccessProfileEntitlements(
            { getAccessProfileEntitlementsV1 } as never,
            'ap-1'
        )

        expect(entitlements).toEqual([{ id: 'ent-1', name: 'Finance Admin' }])
    })
})
