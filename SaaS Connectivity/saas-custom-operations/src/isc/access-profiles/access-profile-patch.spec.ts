import { describe, expect, it, vi } from 'vitest'
import {
    appendAccessProfileDescription,
    patchAccessProfileComposition,
    removeAccessProfileEntitlements,
} from './access-profile-patch'

describe('isc/access-profiles patch helpers', () => {
    it('Remove access profile entitlements', async () => {
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [
                { id: 'ent-1', name: 'One' },
                { id: 'ent-2', name: 'Two' },
            ],
        })
        const patchAccessProfileV1 = vi.fn().mockResolvedValue({})

        await removeAccessProfileEntitlements(
            { getAccessProfileEntitlementsV1, patchAccessProfileV1 } as never,
            'ap-v',
            ['ent-1']
        )

        expect(patchAccessProfileV1).toHaveBeenCalledWith({
            id: 'ap-v',
            jsonPatchOperation: [
                {
                    op: 'replace',
                    path: '/entitlements',
                    value: [{ id: 'ent-2', name: 'Two' }],
                },
            ],
        })
    })

    it('Append access profile description', async () => {
        const getAccessProfileV1 = vi.fn().mockResolvedValue({
            data: { description: 'AP text' },
        })
        const patchAccessProfileV1 = vi.fn().mockResolvedValue({})

        await appendAccessProfileDescription({ getAccessProfileV1, patchAccessProfileV1 } as never, 'ap-v', 'audit')

        expect(patchAccessProfileV1).toHaveBeenCalledWith({
            id: 'ap-v',
            jsonPatchOperation: [
                {
                    op: 'replace',
                    path: '/description',
                    value: 'AP text\naudit',
                },
            ],
        })
    })

    it('patchAccessProfileComposition combines entitlement removal and description in one PATCH', async () => {
        const getAccessProfileEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-1' }],
        })
        const getAccessProfileV1 = vi.fn().mockResolvedValue({
            data: { description: 'desc' },
        })
        const patchAccessProfileV1 = vi.fn().mockResolvedValue({})

        await patchAccessProfileComposition(
            { getAccessProfileEntitlementsV1, getAccessProfileV1, patchAccessProfileV1 } as never,
            'ap-v',
            { removeEntitlementIds: ['ent-1'], descriptionAppend: 'audit' }
        )

        expect(patchAccessProfileV1).toHaveBeenCalledOnce()
        expect(patchAccessProfileV1.mock.calls[0][0].jsonPatchOperation).toHaveLength(2)
    })
})
