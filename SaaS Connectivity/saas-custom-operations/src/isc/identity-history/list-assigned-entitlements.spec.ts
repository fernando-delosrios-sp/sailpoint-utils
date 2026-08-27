import { describe, expect, it, vi } from 'vitest'
import { listAssignedEntitlements } from './list-assigned-entitlements'
import { listAssignedEntitlementsOffline } from './offline-entitlements'

describe('isc/identity-history entitlements', () => {
    it('listAssignedEntitlements maps privileged flag from identity history API', async () => {
        const identityHistory = {
            listIdentityAccessItemsV1: vi.fn().mockResolvedValue({
                data: [
                    { id: 'ent-1', displayName: 'Admin', privileged: true },
                    { id: 'ent-2', displayName: 'Read', privileged: false },
                ],
            }),
        }

        const entitlements = await listAssignedEntitlements(identityHistory as never, 'ident-1')

        expect(identityHistory.listIdentityAccessItemsV1).toHaveBeenCalledWith({
            id: 'ident-1',
            type: 'entitlement',
            xSailPointExperimental: 'true',
        })
        expect(entitlements).toEqual([
            { id: 'ent-1', displayName: 'Admin', privileged: true },
            { id: 'ent-2', displayName: 'Read', privileged: false },
        ])
    })

    it('listAssignedEntitlementsOffline returns canned privileged entitlement for offline identity', () => {
        expect(listAssignedEntitlementsOffline('offline-identity')).toEqual([
            { id: 'offline-ent-a', displayName: 'Offline Entitlement A', privileged: true },
            { id: 'offline-ent-b', displayName: 'Offline Entitlement B', privileged: false },
        ])
    })
})
