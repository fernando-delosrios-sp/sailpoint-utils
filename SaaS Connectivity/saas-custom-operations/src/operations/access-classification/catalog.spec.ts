import { describe, expect, it, vi } from 'vitest'
import type { EntitlementsApi } from 'sailpoint-api-client'
import { listEntitlementCatalog } from './catalog'

function row(id: string) {
    return { id, privilegeLevel: { effective: 'HIGH', direct: null }, accessModelMetadata: undefined }
}

describe('listEntitlementCatalog', () => {
    it('sorts by id and continues with searchAfter after a full page', async () => {
        const first = Array.from({ length: 250 }, (_, index) => row(`ent-${index}`))
        const listEntitlementsV1 = vi
            .fn()
            .mockResolvedValueOnce({ data: first })
            .mockResolvedValueOnce({ data: [row('ent-250')] })
        const entitlements = { listEntitlementsV1 } as unknown as EntitlementsApi

        const items = await listEntitlementCatalog(entitlements)

        expect(listEntitlementsV1).toHaveBeenNthCalledWith(1, { limit: 250, sorters: 'id' })
        expect(listEntitlementsV1).toHaveBeenNthCalledWith(2, {
            limit: 250,
            sorters: 'id',
            searchAfter: 'ent-249',
        })
        expect(items).toHaveLength(251)
        expect(items[250]?.id).toBe('ent-250')
    })
})
