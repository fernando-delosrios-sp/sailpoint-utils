import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it, vi } from 'vitest'
import { buildCreateFormDefinitionPayload, loadFormSeed } from '../../isc/forms'
import { launchForm } from './index'

const seed = loadFormSeed({
    name: 'seed',
    description: 'Seed description',
    formInput: [{ id: 'message', type: 'STRING', label: 'Message' }],
    formElements: [{ id: 'message', elementType: 'TEXT' }],
})

function createFormsMock() {
    const searchFormDefinitionsByTenantV1 = vi.fn().mockResolvedValue({ data: { results: [] } })
    const createFormDefinitionV1 = vi.fn().mockResolvedValue({ data: { id: 'definition-1' } })
    const createFormInstanceV1 = vi.fn().mockResolvedValue({
        data: {
            standAloneFormUrl: 'https://tenant.example/forms/instance-1',
            state: 'ASSIGNED',
        },
    })

    return {
        forms: {
            searchFormDefinitionsByTenantV1,
            createFormDefinitionV1,
            createFormInstanceV1,
        } as never,
        searchFormDefinitionsByTenantV1,
        createFormDefinitionV1,
        createFormInstanceV1,
    }
}

describe('launchForm', () => {
    it('Ensure then create returns form URL and uses isc forms API helpers', async () => {
        const mocks = createFormsMock()
        const template = buildCreateFormDefinitionPayload('Review access', 'owner-1', seed, seed.description)

        const result = await launchForm({
            forms: mocks.forms,
            definition: { formName: 'Review access', ownerId: 'owner-1', template },
            recipientId: 'recipient-1',
            createdBySourceId: 'source-1',
            formInput: { message: 'Review this access' },
            notification: {
                emailHeader: 'Review required',
                emailBody: 'Open the review form',
                emailRecipients: ['recipient@example.com'],
            },
        })

        expect(mocks.searchFormDefinitionsByTenantV1).toHaveBeenCalledWith({
            filters: 'name eq "Review access"',
        })
        expect(mocks.createFormDefinitionV1).toHaveBeenCalled()
        expect(mocks.createFormInstanceV1).toHaveBeenCalledWith({
            body: expect.objectContaining({ formDefinitionId: 'definition-1' }),
        })
        expect(result.formUrl).toBe('https://tenant.example/forms/instance-1')
    })

    it('Notification fields paired with form URL', async () => {
        const mocks = createFormsMock()

        const result = await launchForm({
            forms: mocks.forms,
            definition: { formDefinitionId: 'definition-1' },
            recipientId: 'recipient-1',
            createdBySourceId: 'source-1',
            formInput: {},
            notification: {
                emailHeader: ({ formUrl }) => `Review at ${formUrl}`,
                emailBody: ({ formUrl }) => `Open ${formUrl}`,
                emailRecipients: ['recipient@example.com'],
            },
        })

        expect(result).toEqual({
            formUrl: 'https://tenant.example/forms/instance-1',
            emailHeader: 'Review at https://tenant.example/forms/instance-1',
            emailBody: 'Open https://tenant.example/forms/instance-1',
            emailRecipients: ['recipient@example.com'],
        })
    })

    it('Optional expire passed through', async () => {
        const mocks = createFormsMock()

        await launchForm({
            forms: mocks.forms,
            definition: { formDefinitionId: 'definition-1' },
            recipientId: 'recipient-1',
            createdBySourceId: 'source-1',
            formInput: {},
            expire: '2026-09-01T00:00:00.000Z',
            notification: {
                emailHeader: 'Review required',
                emailBody: 'Open the review form',
                emailRecipients: ['recipient@example.com'],
            },
        })

        expect(mocks.createFormInstanceV1).toHaveBeenCalledWith({
            body: expect.objectContaining({ expire: '2026-09-01T00:00:00.000Z' }),
        })
    })

    it('Handler owns persist', async () => {
        const mocks = createFormsMock()

        const result = await launchForm({
            forms: mocks.forms,
            definition: { formDefinitionId: 'definition-1' },
            recipientId: 'recipient-1',
            createdBySourceId: 'source-1',
            formInput: {},
            notification: {
                emailHeader: 'Review required',
                emailBody: 'Open the review form',
                emailRecipients: ['recipient@example.com'],
            },
        })

        expect(result).toEqual({
            formUrl: 'https://tenant.example/forms/instance-1',
            emailHeader: 'Review required',
            emailBody: 'Open the review form',
            emailRecipients: ['recipient@example.com'],
        })

        const source = readFileSync(join(__dirname, 'index.ts'), 'utf8')
        expect(source).not.toContain('ctx.persist')
        expect(source).not.toMatch(/from ['"][^'"]*persist-result/)
        expect(source).not.toMatch(/\bpersist\s*\(/)
    })
})
