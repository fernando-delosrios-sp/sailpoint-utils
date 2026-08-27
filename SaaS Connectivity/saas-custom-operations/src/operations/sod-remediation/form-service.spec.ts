import { describe, expect, it, vi } from 'vitest'
import { launchSodRemediationForm } from './form-service'

const baseFormInput = {
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
}

function createFormsMock() {
    const searchFormDefinitionsByTenantV1 = vi.fn().mockResolvedValue({ data: { results: [] } })
    const createFormDefinitionV1 = vi.fn().mockResolvedValue({ data: { id: 'def-created' } })
    const createFormInstanceV1 = vi.fn().mockResolvedValue({
        data: { standAloneFormUrl: 'https://tenant.identitynow.com/form/abc', state: 'ASSIGNED' },
    })
    return {
        forms: {
            searchFormDefinitionsByTenantV1,
            createFormDefinitionV1,
            createFormInstanceV1,
        } as never,
        createFormDefinitionV1,
        createFormInstanceV1,
    }
}

describe('launchSodRemediationForm', () => {
    it('keeps the seed and formInput serialization operation-local', async () => {
        const mocks = createFormsMock()

        const result = await launchSodRemediationForm({
            forms: mocks.forms,
            formName: 'SOD Remediation',
            definitionOwnerId: 'owner-1',
            recipientId: 'owner-1',
            createdBySourceId: 'source-1',
            formInput: baseFormInput,
            notification: {
                emailHeader: 'Review',
                emailBody: ({ formUrl }) => `Open ${formUrl}`,
                emailRecipients: ['owner@example.com'],
            },
        })

        expect(mocks.createFormDefinitionV1).toHaveBeenCalledWith(
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
        expect(mocks.createFormInstanceV1).toHaveBeenCalledWith({
            body: expect.objectContaining({
                formInput: expect.objectContaining({ hasControls: 'true', violationId: 'vio-1' }),
            }),
        })
        expect(result.emailBody).toContain(result.formUrl)
    })

    it('sends false hasControls as string false', async () => {
        const mocks = createFormsMock()

        await launchSodRemediationForm({
            forms: mocks.forms,
            formName: 'SOD Remediation',
            definitionOwnerId: 'owner-1',
            recipientId: 'owner-1',
            createdBySourceId: 'source-1',
            formInput: { ...baseFormInput, hasControls: false, controlOptions: [] },
            notification: {
                emailHeader: 'Review',
                emailBody: 'Open the form',
                emailRecipients: ['owner@example.com'],
            },
        })

        expect(mocks.createFormInstanceV1).toHaveBeenCalledWith({
            body: expect.objectContaining({
                formInput: expect.objectContaining({ hasControls: 'false' }),
            }),
        })
    })
})
