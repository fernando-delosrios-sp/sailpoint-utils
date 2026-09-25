import { describe, expect, it, vi } from 'vitest'
import { listMachineAccounts, MACHINE_ACCOUNT_PAGE_SIZE } from './list-machine-accounts'

describe('machine accounts ISC client', () => {
    it('paginates and maps the machineIdentity node', async () => {
        const firstPage = Array.from({ length: MACHINE_ACCOUNT_PAGE_SIZE }, (_, index) => ({
            id: `ma-${index}`,
            name: `Account ${index}`,
            nativeIdentity: `native-${index}`,
            classificationMethod: 'SOURCE',
            connectorAttributes: { groups: [`group-${index}`] },
            manuallyEdited: false,
            locked: false,
            enabled: true,
            hasEntitlements: true,
            machineIdentity: { id: `mi-${index}`, name: `Identity ${index}` },
            source: { id: 'src-1', name: 'Source' },
        }))
        const api = {
            listMachineAccountsV1: vi
                .fn()
                .mockResolvedValueOnce({ data: firstPage })
                .mockResolvedValueOnce({
                    data: [
                        {
                            ...firstPage[0],
                            id: 'ma-last',
                            machineIdentity: { id: 'mi-last', name: 'Last' },
                        },
                    ],
                }),
        }

        const result = await listMachineAccounts(api as never)

        expect(api.listMachineAccountsV1).toHaveBeenNthCalledWith(
            1,
            expect.objectContaining({ limit: MACHINE_ACCOUNT_PAGE_SIZE, offset: 0, xSailPointExperimental: 'true' })
        )
        expect(api.listMachineAccountsV1).toHaveBeenNthCalledWith(
            2,
            expect.objectContaining({ offset: MACHINE_ACCOUNT_PAGE_SIZE })
        )
        expect(result.at(-1)).toMatchObject({
            id: 'ma-last',
            machineIdentity: { id: 'mi-last' },
            source: { id: 'src-1' },
            connectorAttributes: { groups: ['group-0'] },
        })
    })

    it('skips unlinked machine accounts', async () => {
        const api = {
            listMachineAccountsV1: vi.fn().mockResolvedValue({
                data: [
                    {
                        id: 'ma-unlinked',
                        name: 'Unlinked',
                        nativeIdentity: 'unlinked',
                        classificationMethod: 'SOURCE',
                        connectorAttributes: {},
                        manuallyEdited: false,
                        locked: false,
                        enabled: true,
                        hasEntitlements: false,
                        source: { id: 'src-1' },
                    },
                ],
            }),
        }

        await expect(listMachineAccounts(api as never)).resolves.toEqual([])
    })
})
