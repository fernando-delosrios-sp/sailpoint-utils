import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { getMachineIdentity } from './get-machine-identity'
import { listMachineIdentities, MACHINE_IDENTITY_PAGE_SIZE } from './list-machine-identities'
import { patchUserEntitlements } from './patch-user-entitlements'
import { resolveMachineIdentityByIdentityId } from './resolve-by-identity-id'

describe('isc/machine-identities', () => {
    it('List paginates machine identities', async () => {
        const firstPage = Array.from({ length: MACHINE_IDENTITY_PAGE_SIZE }, (_, index) => ({
            id: `mi-${index}`,
            userEntitlements: [],
        }))
        const secondPage = [{ id: 'mi-last', userEntitlements: [] }]
        const listMachineIdentitiesV1 = vi
            .fn()
            .mockResolvedValueOnce({ data: firstPage })
            .mockResolvedValueOnce({ data: secondPage })

        const records = await listMachineIdentities({ listMachineIdentitiesV1 } as never)

        expect(listMachineIdentitiesV1).toHaveBeenNthCalledWith(1, {
            offset: 0,
            limit: MACHINE_IDENTITY_PAGE_SIZE,
            xSailPointExperimental: 'true',
        })
        expect(listMachineIdentitiesV1).toHaveBeenNthCalledWith(2, {
            offset: MACHINE_IDENTITY_PAGE_SIZE,
            limit: MACHINE_IDENTITY_PAGE_SIZE,
            xSailPointExperimental: 'true',
        })
        expect(records).toHaveLength(MACHINE_IDENTITY_PAGE_SIZE + 1)
        expect(records.at(-1)?.id).toBe('mi-last')
    })

    it('Get returns user entitlements', async () => {
        const getMachineIdentityV1 = vi.fn().mockResolvedValue({
            data: {
                id: 'mi-1',
                cisIdentityId: 'cis-1',
                userEntitlements: [{ sourceId: 'src-1', entitlementId: 'ent-1' }],
            },
        })

        const identity = await getMachineIdentity({ getMachineIdentityV1 } as never, 'mi-1')

        expect(getMachineIdentityV1).toHaveBeenCalledWith({
            id: 'mi-1',
            xSailPointExperimental: 'true',
        })
        expect(identity.userEntitlements).toEqual([{ sourceId: 'src-1', entitlementId: 'ent-1' }])
    })

    it('List API failure surfaces error', async () => {
        const listMachineIdentitiesV1 = vi.fn().mockRejectedValue({ response: { status: 500 }, message: 'boom' })

        await expect(listMachineIdentities({ listMachineIdentitiesV1 } as never)).rejects.toBeInstanceOf(ConnectorError)
        await expect(listMachineIdentities({ listMachineIdentitiesV1 } as never)).rejects.toThrow(/HTTP 500/)
    })

    it('Experimental header sent when required', async () => {
        const listMachineIdentitiesV1 = vi.fn().mockResolvedValue({ data: [] })
        const getMachineIdentityV1 = vi.fn().mockResolvedValue({ data: { id: 'mi-1', userEntitlements: [] } })
        const updateMachineIdentityV1 = vi.fn().mockResolvedValue({})

        await listMachineIdentities({ listMachineIdentitiesV1 } as never)
        await getMachineIdentity({ getMachineIdentityV1 } as never, 'mi-1')
        await patchUserEntitlements({ updateMachineIdentityV1 } as never, 'mi-1', [])

        expect(listMachineIdentitiesV1.mock.calls[0]?.[0].xSailPointExperimental).toBe('true')
        expect(getMachineIdentityV1.mock.calls[0]?.[0].xSailPointExperimental).toBe('true')
        expect(updateMachineIdentityV1.mock.calls[0]?.[0].xSailPointExperimental).toBe('true')
    })

    it('Patch sends complete refs', async () => {
        const updateMachineIdentityV1 = vi.fn().mockResolvedValue({})
        const refs = [
            { sourceId: 'src-1', entitlementId: 'ent-a' },
            { sourceId: 'src-3', entitlementId: 'ent-c' },
        ]

        await patchUserEntitlements({ updateMachineIdentityV1 } as never, 'mi-1', refs)

        expect(updateMachineIdentityV1).toHaveBeenCalledWith({
            id: 'mi-1',
            requestBody: [
                {
                    op: 'replace',
                    path: '/userEntitlements',
                    value: refs,
                },
            ],
            xSailPointExperimental: 'true',
        })
    })

    it('Match by machine identity id', async () => {
        const listMachineIdentitiesV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'mi-1', cisIdentityId: 'cis-other', userEntitlements: [] }],
        })

        const match = await resolveMachineIdentityByIdentityId({ listMachineIdentitiesV1 } as never, 'mi-1')

        expect(listMachineIdentitiesV1).toHaveBeenCalledWith(
            expect.objectContaining({ filters: 'id eq "mi-1"', xSailPointExperimental: 'true' })
        )
        expect(match?.id).toBe('mi-1')
    })

    it('Match by cisIdentityId', async () => {
        const listMachineIdentitiesV1 = vi
            .fn()
            .mockResolvedValueOnce({ data: [] })
            .mockResolvedValueOnce({
                data: [{ id: 'mi-2', cisIdentityId: 'cis-target', userEntitlements: [] }],
            })

        const match = await resolveMachineIdentityByIdentityId({ listMachineIdentitiesV1 } as never, 'cis-target')

        expect(listMachineIdentitiesV1).toHaveBeenNthCalledWith(
            1,
            expect.objectContaining({ filters: 'id eq "cis-target"' })
        )
        expect(listMachineIdentitiesV1).toHaveBeenNthCalledWith(
            2,
            expect.objectContaining({ filters: 'cisIdentityId eq "cis-target"' })
        )
        expect(match?.id).toBe('mi-2')
    })

    it('Unknown identityId is not found', async () => {
        const listMachineIdentitiesV1 = vi.fn().mockResolvedValue({ data: [] })

        const match = await resolveMachineIdentityByIdentityId({ listMachineIdentitiesV1 } as never, 'unknown')

        expect(match).toBeUndefined()
    })

    it('Machine identities API separated', async () => {
        const { readdirSync, existsSync } = await import('node:fs')
        const { join } = await import('node:path')
        const folder = join(__dirname)
        expect(existsSync(join(folder, 'index.ts'))).toBe(true)
        const files = readdirSync(folder)
        expect(files).toContain('list-machine-identities.ts')
        expect(files).not.toContain('accounts.ts')
        expect(files).not.toContain('entitlements.ts')
    })
})
