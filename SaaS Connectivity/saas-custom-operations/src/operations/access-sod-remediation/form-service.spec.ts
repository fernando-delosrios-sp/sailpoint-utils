import { describe, expect, it, vi } from 'vitest'
import { createAccessSodRemediationInstance, hasAssignedRemediationInstance, serializeAccessSodFormInputForCreate } from './form-service'

describe('serializeAccessSodFormInputForCreate', () => {
    it('JSON-stringifies entitlement id lists for ISC STRING formInput fields', () => {
        expect(
            serializeAccessSodFormInputForCreate({
                accessItemId: 'role-1',
                accessItemType: 'ROLE',
                accessItemTypeTagHtml: "<span style='color:#1d4ed8; font-size:90%; background-color:#dbeafe; padding:2px 6px; border-radius:4px;'>role</span>",
                accessItemName: 'Finance Role',
                policyId: 'policy-1',
                policyName: 'AP/AR Separation',
                groupAIds: ['ent-a', 'ent-b'],
                groupBIds: ['ent-c'],
                groupColumnsHtmlPlain: '<p>plain</p>',
                groupColumnsHtmlWhenGroupARemoved: '<p>A removed</p>',
                groupColumnsHtmlWhenGroupBRemoved: '<p>B removed</p>',
            })
        ).toMatchObject({
            groupAIds: '["ent-a","ent-b"]',
            groupBIds: '["ent-c"]',
        })
    })
})

describe('createAccessSodRemediationInstance', () => {
    it('sends JSON-string group ids to createFormInstanceV1', async () => {
        const createFormInstanceV1 = vi.fn().mockResolvedValue({
            data: { standAloneFormUrl: 'https://tenant.identitynow.com/form/abc', state: 'ASSIGNED' },
        })
        const forms = { createFormInstanceV1 } as never

        await createAccessSodRemediationInstance({
            forms,
            formDefinitionId: 'def-1',
            recipientId: 'owner-1',
            createdBySourceId: 'source-1',
            formInput: {
                accessItemId: 'role-1',
                accessItemType: 'ROLE',
                accessItemTypeTagHtml: "<span style='color:#1d4ed8; font-size:90%; background-color:#dbeafe; padding:2px 6px; border-radius:4px;'>role</span>",
                accessItemName: 'Finance Role',
                policyId: 'policy-1',
                policyName: 'AP/AR Separation',
                groupAIds: ['ent-a'],
                groupBIds: ['ent-c'],
                groupColumnsHtmlPlain: '<p>plain</p>',
                groupColumnsHtmlWhenGroupARemoved: '<p>A removed</p>',
                groupColumnsHtmlWhenGroupBRemoved: '<p>B removed</p>',
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
})

describe('hasAssignedRemediationInstance', () => {
    it('filters ASSIGNED instances client-side because state is not a list filter field', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    state: 'SUBMITTED',
                    formInput: { accessItemId: 'role-1', policyId: 'policy-1' },
                },
                {
                    state: 'ASSIGNED',
                    formInput: { accessItemId: 'role-1', policyId: 'policy-1' },
                },
            ],
        })

        const forms = { searchFormInstancesByTenantV1 } as never
        const result = await hasAssignedRemediationInstance(forms, 'form-def-1', 'role-1', 'policy-1')

        expect(searchFormInstancesByTenantV1).toHaveBeenCalledWith({
            filters: 'formDefinitionId eq "form-def-1"',
            limit: 250,
        })
        expect(result).toBe(true)
    })

    it('returns false when only non-assigned instances match', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    state: 'COMPLETED',
                    formInput: { accessItemId: 'role-1', policyId: 'policy-1' },
                },
            ],
        })

        const forms = { searchFormInstancesByTenantV1 } as never
        const result = await hasAssignedRemediationInstance(forms, 'form-def-1', 'role-1', 'policy-1')

        expect(result).toBe(false)
    })
})
