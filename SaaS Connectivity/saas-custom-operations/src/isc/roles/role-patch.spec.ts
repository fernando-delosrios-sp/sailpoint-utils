import { describe, expect, it, vi } from 'vitest'
import {
    appendRoleDescription,
    detachRoleAccessProfiles,
    patchRoleComposition,
    removeRoleEntitlements,
} from './role-patch'

describe('isc/roles role patch helpers', () => {
    it('Detach access profiles from role', async () => {
        const getRoleV1 = vi.fn().mockResolvedValue({
            data: {
                accessProfiles: [
                    { id: 'ap-a', name: 'AP A' },
                    { id: 'ap-b', name: 'AP B' },
                ],
            },
        })
        const patchRoleV1 = vi.fn().mockResolvedValue({})

        await detachRoleAccessProfiles({ getRoleV1, patchRoleV1 } as never, 'role-r', ['ap-a'])

        expect(patchRoleV1).toHaveBeenCalledWith({
            id: 'role-r',
            jsonPatchOperation: [
                {
                    op: 'replace',
                    path: '/accessProfiles',
                    value: [{ id: 'ap-b', name: 'AP B' }],
                },
            ],
        })
    })

    it('Remove direct role entitlements', async () => {
        const getRoleEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [
                { id: 'ent-1', name: 'One' },
                { id: 'ent-2', name: 'Two' },
            ],
        })
        const patchRoleV1 = vi.fn().mockResolvedValue({})

        await removeRoleEntitlements({ getRoleEntitlementsV1, patchRoleV1 } as never, 'role-r', ['ent-1'])

        expect(patchRoleV1).toHaveBeenCalledWith({
            id: 'role-r',
            jsonPatchOperation: [
                {
                    op: 'replace',
                    path: '/entitlements',
                    value: [{ id: 'ent-2', name: 'Two' }],
                },
            ],
        })
    })

    it('Append role description', async () => {
        const getRoleV1 = vi.fn().mockResolvedValue({
            data: { description: 'Existing text' },
        })
        const patchRoleV1 = vi.fn().mockResolvedValue({})

        await appendRoleDescription({ getRoleV1, patchRoleV1 } as never, 'role-r', 'audit line')

        expect(patchRoleV1).toHaveBeenCalledWith({
            id: 'role-r',
            jsonPatchOperation: [
                {
                    op: 'replace',
                    path: '/description',
                    value: 'Existing text\naudit line',
                },
            ],
        })
    })

    it('patchRoleComposition combines detach, remove, and description in one PATCH', async () => {
        const getRoleV1 = vi.fn().mockResolvedValue({
            data: {
                description: 'Role desc',
                accessProfiles: [{ id: 'ap-a' }, { id: 'ap-b' }],
            },
        })
        const getRoleEntitlementsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'ent-1' }, { id: 'ent-2' }],
        })
        const patchRoleV1 = vi.fn().mockResolvedValue({})

        await patchRoleComposition({ getRoleV1, getRoleEntitlementsV1, patchRoleV1 } as never, 'role-r', {
            detachAccessProfileIds: ['ap-a'],
            removeEntitlementIds: ['ent-1'],
            descriptionAppend: 'audit',
        })

        expect(patchRoleV1).toHaveBeenCalledOnce()
        expect(patchRoleV1.mock.calls[0][0].jsonPatchOperation).toHaveLength(3)
    })
})
