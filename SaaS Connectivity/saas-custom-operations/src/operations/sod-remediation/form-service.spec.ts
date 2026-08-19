import { describe, expect, it, vi } from 'vitest'
import { createSodRemediationInstance, ensureSodFormDefinition } from './form-service'

describe('ensureSodFormDefinition', () => {
    it('creates form definition from bundled seed when absent', async () => {
        const searchFormDefinitionsByTenantV1 = vi.fn().mockResolvedValue({ data: { results: [] } })
        const createFormDefinitionV1 = vi.fn().mockResolvedValue({ data: { id: 'def-created' } })
        const forms = {
            searchFormDefinitionsByTenantV1,
            createFormDefinitionV1,
        } as never

        const formDefinitionId = await ensureSodFormDefinition(forms, 'SOD Remediation', 'owner-1')

        expect(formDefinitionId).toBe('def-created')
        expect(searchFormDefinitionsByTenantV1).toHaveBeenCalledWith({
            filters: 'name eq "SOD Remediation"',
        })
        expect(createFormDefinitionV1).toHaveBeenCalledWith(
            expect.objectContaining({
                body: expect.objectContaining({
                    name: 'SOD Remediation',
                    owner: { id: 'owner-1', type: 'IDENTITY' },
                    formInput: expect.arrayContaining([
                        expect.objectContaining({ id: 'hasControls', type: 'STRING' }),
                        expect.objectContaining({ id: 'violationId', type: 'STRING' }),
                    ]),
                }),
            })
        )
    })
})

describe('createSodRemediationInstance', () => {
    it('coerces hasControls boolean to string for ISC STRING formInput field', async () => {
        const createFormInstanceV1 = vi.fn().mockResolvedValue({
            data: { standAloneFormUrl: 'https://tenant.identitynow.com/form/abc', state: 'ASSIGNED' },
        })
        const forms = { createFormInstanceV1 } as never

        await createSodRemediationInstance({
            forms,
            formDefinitionId: 'def-1',
            recipientId: 'owner-1',
            createdBySourceId: 'source-1',
            formInput: {
                targetIdentityName: 'Alice Example',
                policyName: 'AP vs AP',
                situationSummaryHtml: '<p>summary</p>',
                groupColumnsHtmlPlain: '<p>plain</p>',
                groupColumnsHtmlWhenGroupARemoved: '<p>A removed</p>',
                groupColumnsHtmlWhenGroupBRemoved: '<p>B removed</p>',
                hasControls: true,
                violationId: 'vio-1',
                targetIdentityId: 'ident-1',
                groupAAccessSearch: 'id:ent-a',
                groupBAccessSearch: 'id:ent-b',
                controlOptions: [{ label: 'Control 1', value: 'ctrl-1' }],
            },
        })

        expect(createFormInstanceV1).toHaveBeenCalledWith(
            expect.objectContaining({
                body: expect.objectContaining({
                    formInput: expect.objectContaining({
                        hasControls: 'true',
                        violationId: 'vio-1',
                        targetIdentityId: 'ident-1',
                    }),
                }),
            })
        )
    })

    it('sends false hasControls as string false', async () => {
        const createFormInstanceV1 = vi.fn().mockResolvedValue({
            data: { standAloneFormUrl: 'https://tenant.identitynow.com/form/abc', state: 'ASSIGNED' },
        })
        const forms = { createFormInstanceV1 } as never

        await createSodRemediationInstance({
            forms,
            formDefinitionId: 'def-1',
            recipientId: 'owner-1',
            createdBySourceId: 'source-1',
            formInput: {
                targetIdentityName: 'Alice Example',
                policyName: 'AP vs AP',
                situationSummaryHtml: '<p>summary</p>',
                groupColumnsHtmlPlain: '<p>plain</p>',
                groupColumnsHtmlWhenGroupARemoved: '<p>A removed</p>',
                groupColumnsHtmlWhenGroupBRemoved: '<p>B removed</p>',
                hasControls: false,
                violationId: 'vio-1',
                targetIdentityId: 'ident-1',
                groupAAccessSearch: 'id:ent-a',
                groupBAccessSearch: 'id:ent-b',
                controlOptions: [],
            },
        })

        expect(createFormInstanceV1).toHaveBeenCalledWith(
            expect.objectContaining({
                body: expect.objectContaining({
                    formInput: expect.objectContaining({
                        hasControls: 'false',
                    }),
                }),
            })
        )
    })
})
