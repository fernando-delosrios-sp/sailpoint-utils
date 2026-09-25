import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { listEntitlementsByValue, listEntitlementsByValues } from './list-by-value'

describe('isc/entitlements', () => {
    it('Value equality match', async () => {
        const listEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-1', value: 'CN=Admins', source: { id: 'src-1' } }],
        })

        const matches = await listEntitlementsByValue({ listEntitlementsV1 } as never, 'CN=Admins')

        expect(listEntitlementsV1).toHaveBeenCalledWith({
            filters: 'value eq "CN=Admins"',
            offset: 0,
            limit: 250,
        })
        expect(matches).toEqual([{ id: 'ent-1', sourceId: 'src-1', value: 'CN=Admins' }])
    })

    it('No match returns empty list', async () => {
        const listEntitlementsV1 = vi.fn().mockResolvedValue({ data: [] })

        const matches = await listEntitlementsByValue({ listEntitlementsV1 } as never, 'missing')

        expect(matches).toEqual([])
    })

    it('Quotes in value are escaped', async () => {
        const listEntitlementsV1 = vi.fn().mockResolvedValue({ data: [] })

        await listEntitlementsByValue({ listEntitlementsV1 } as never, 'CN="Quoted"')

        expect(listEntitlementsV1).toHaveBeenCalledWith(
            expect.objectContaining({ filters: 'value eq "CN=""Quoted"""' })
        )
    })

    it('Batches multiple values into one membership filter', async () => {
        const listEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [
                { id: 'ent-1', value: 'CN=A', source: { id: 'src-1' } },
                { id: 'ent-2', value: 'CN=B', source: { id: 'src-1' } },
            ],
        })

        const matches = await listEntitlementsByValues({ listEntitlementsV1 } as never, ['CN=A', 'CN=B', 'CN=A'])

        expect(listEntitlementsV1).toHaveBeenCalledTimes(1)
        expect(listEntitlementsV1).toHaveBeenCalledWith({
            filters: 'value in ("CN=A","CN=B")',
            offset: 0,
            limit: 250,
        })
        expect(matches).toHaveLength(2)
    })

    it('API failure surfaces error', async () => {
        const listEntitlementsV1 = vi.fn().mockRejectedValue({ response: { status: 403 }, message: 'forbidden' })

        await expect(listEntitlementsByValue({ listEntitlementsV1 } as never, 'CN=A')).rejects.toBeInstanceOf(
            ConnectorError
        )
        await expect(listEntitlementsByValue({ listEntitlementsV1 } as never, 'CN=A')).rejects.toThrow(/HTTP 403/)
    })

    it('Entitlements API separated', async () => {
        const { readdirSync, existsSync } = await import('node:fs')
        const { join } = await import('node:path')
        const folder = join(__dirname)
        expect(existsSync(join(folder, 'index.ts'))).toBe(true)
        const files = readdirSync(folder)
        expect(files).toContain('list-by-value.ts')
        expect(files).not.toContain('machine-identities.ts')
        expect(files).not.toContain('accounts.ts')
    })
})
