import { describe, expect, it, vi } from 'vitest'
import { createAccessModelSodRemediationInstance, serializeAccessModelSodFormInputForCreate } from './form-service'

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
