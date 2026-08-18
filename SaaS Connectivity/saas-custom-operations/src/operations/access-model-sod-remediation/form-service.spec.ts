import { describe, expect, it, vi } from 'vitest'
import {
    createAccessModelSodRemediationInstance,
    createAssignedRemediationInstanceCache,
    hasAssignedRemediationInstance,
    loadAssignedRemediationInstances,
    serializeAccessModelSodFormInputForCreate,
} from './form-service'

const baseFormInput = {
    parentRequestId: 'scan-parent-1',
    accessItemId: 'role-1',
    accessItemType: 'ROLE',
    accessItemTypeTagHtml:
        "<span style='color:#1d4ed8; font-size:90%; background-color:#dbeafe; padding:2px 6px; border-radius:4px;'>role</span>",
    accessItemName: 'Finance Role',
    policyId: 'policy-1',
    policyName: 'AP/AR Separation',
    groupAIds: ['ent-a', 'ent-b'],
    groupBIds: ['ent-c'],
    groupColumnsHtmlPlain: '<p>plain</p>',
    groupColumnsHtmlWhenGroupARemoved: '<p>A removed</p>',
    groupColumnsHtmlWhenGroupBRemoved: '<p>B removed</p>',
}

describe('serializeAccessModelSodFormInputForCreate', () => {
    it('JSON-stringifies entitlement id lists for ISC STRING formInput fields', () => {
        expect(serializeAccessModelSodFormInputForCreate(baseFormInput)).toMatchObject({
            parentRequestId: 'scan-parent-1',
            groupAIds: '["ent-a","ent-b"]',
            groupBIds: '["ent-c"]',
        })
    })
})

describe('createAccessModelSodRemediationInstance', () => {
    it('sends JSON-string group ids to createFormInstanceV1', async () => {
        const createFormInstanceV1 = vi.fn().mockResolvedValue({
            data: { standAloneFormUrl: 'https://tenant.identitynow.com/form/abc', state: 'ASSIGNED' },
        })
        const forms = { createFormInstanceV1 } as never

        await createAccessModelSodRemediationInstance({
            forms,
            formDefinitionId: 'def-1',
            recipientId: 'owner-1',
            createdBySourceId: 'source-1',
            formInput: {
                ...baseFormInput,
                groupAIds: ['ent-a'],
            },
        })

        expect(createFormInstanceV1).toHaveBeenCalledWith(
            expect.objectContaining({
                body: expect.objectContaining({
                    formInput: expect.objectContaining({
                        groupAIds: '["ent-a"]',
                        groupBIds: '["ent-c"]',
                    }),
                }),
            })
        )
    })

    it('Form input carries parent request id', async () => {
        const createFormInstanceV1 = vi.fn().mockResolvedValue({
            data: { standAloneFormUrl: 'https://tenant.identitynow.com/form/abc', state: 'ASSIGNED' },
        })
        const forms = { createFormInstanceV1 } as never

        await createAccessModelSodRemediationInstance({
            forms,
            formDefinitionId: 'def-1',
            recipientId: 'owner-1',
            createdBySourceId: 'source-1',
            formInput: baseFormInput,
        })

        expect(createFormInstanceV1).toHaveBeenCalledWith(
            expect.objectContaining({
                body: expect.objectContaining({
                    formInput: expect.objectContaining({
                        parentRequestId: 'scan-parent-1',
                    }),
                }),
            })
        )
    })
})

describe('hasAssignedRemediationInstance', () => {
    it('Same parent request skips duplicate pending form', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    state: 'SUBMITTED',
                    formInput: {
                        parentRequestId: 'scan-parent-1',
                        accessItemId: 'role-1',
                        policyId: 'policy-1',
                    },
                },
                {
                    state: 'ASSIGNED',
                    formInput: {
                        parentRequestId: 'scan-parent-1',
                        accessItemId: 'role-1',
                        policyId: 'policy-1',
                    },
                },
            ],
        })

        const forms = { searchFormInstancesByTenantV1 } as never
        const result = await hasAssignedRemediationInstance(
            forms,
            'form-def-1',
            'scan-parent-1',
            'role-1',
            'policy-1'
        )

        expect(searchFormInstancesByTenantV1).toHaveBeenCalledWith({
            filters: 'formDefinitionId eq "form-def-1"',
            limit: 250,
        })
        expect(result).toBe(true)
    })

    it('Different parent request does not skip', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    state: 'ASSIGNED',
                    formInput: {
                        parentRequestId: 'scan-parent-1',
                        accessItemId: 'role-1',
                        policyId: 'policy-1',
                    },
                },
            ],
        })

        const forms = { searchFormInstancesByTenantV1 } as never
        const result = await hasAssignedRemediationInstance(
            forms,
            'form-def-1',
            'scan-parent-2',
            'role-1',
            'policy-1'
        )

        expect(result).toBe(false)
    })

    it('Legacy instance without parentRequestId does not skip', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    state: 'ASSIGNED',
                    formInput: { accessItemId: 'role-1', policyId: 'policy-1' },
                },
            ],
        })

        const forms = { searchFormInstancesByTenantV1 } as never
        const result = await hasAssignedRemediationInstance(
            forms,
            'form-def-1',
            'scan-parent-3',
            'role-1',
            'policy-1'
        )

        expect(result).toBe(false)
    })

    it('Non-assigned instance does not skip', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    state: 'COMPLETED',
                    formInput: {
                        parentRequestId: 'scan-parent-1',
                        accessItemId: 'role-1',
                        policyId: 'policy-1',
                    },
                },
            ],
        })

        const forms = { searchFormInstancesByTenantV1 } as never
        const result = await hasAssignedRemediationInstance(
            forms,
            'form-def-1',
            'scan-parent-1',
            'role-1',
            'policy-1'
        )

        expect(result).toBe(false)
    })

    it('One search per scan for pending instances', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    state: 'ASSIGNED',
                    formInput: {
                        parentRequestId: 'scan-parent-1',
                        accessItemId: 'role-1',
                        policyId: 'policy-1',
                    },
                },
                {
                    state: 'ASSIGNED',
                    formInput: {
                        parentRequestId: 'scan-parent-1',
                        accessItemId: 'role-2',
                        policyId: 'policy-2',
                    },
                },
            ],
        })
        const forms = { searchFormInstancesByTenantV1 } as never
        const cache = createAssignedRemediationInstanceCache('form-def-1')

        await expect(
            hasAssignedRemediationInstance(forms, 'form-def-1', 'scan-parent-1', 'role-1', 'policy-1', cache)
        ).resolves.toBe(true)
        await expect(
            hasAssignedRemediationInstance(forms, 'form-def-1', 'scan-parent-1', 'role-2', 'policy-2', cache)
        ).resolves.toBe(true)
        await expect(
            hasAssignedRemediationInstance(forms, 'form-def-1', 'scan-parent-1', 'role-3', 'policy-3', cache)
        ).resolves.toBe(false)

        expect(searchFormInstancesByTenantV1).toHaveBeenCalledTimes(1)
    })
})

describe('loadAssignedRemediationInstances', () => {
    it('loads assigned parent request, access item, and policy triples once', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    state: 'ASSIGNED',
                    formInput: {
                        parentRequestId: 'scan-parent-1',
                        accessItemId: 'role-1',
                        policyId: 'policy-1',
                    },
                },
            ],
        })
        const forms = { searchFormInstancesByTenantV1 } as never

        const cache = await loadAssignedRemediationInstances(forms, 'form-def-1')

        expect(searchFormInstancesByTenantV1).toHaveBeenCalledTimes(1)
        expect(cache.assignedPairs.has('scan-parent-1:role-1:policy-1')).toBe(true)
    })
})
