import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { createRemediationInstance, ensureFormDefinition, formatFormsApiError } from './sod-form-service'

describe('sod-form-service', () => {
    it('ensureFormDefinition searches tenant and creates from seed when missing', async () => {
        const searchFormDefinitionsByTenantV1 = vi.fn().mockResolvedValue({ data: { results: [] } })
        const createFormDefinitionV1 = vi.fn().mockResolvedValue({ data: { id: 'def-new' } })
        const forms = { searchFormDefinitionsByTenantV1, createFormDefinitionV1, createFormInstanceV1: vi.fn() }

        const id = await ensureFormDefinition(forms, 'SOD Remediation', 'owner-1')

        expect(searchFormDefinitionsByTenantV1).toHaveBeenCalledWith({ filters: 'name eq "SOD Remediation"' })
        expect(createFormDefinitionV1).toHaveBeenCalledWith(
            expect.objectContaining({ body: expect.objectContaining({ name: 'SOD Remediation', owner: { type: 'IDENTITY', id: 'owner-1' } }) })
        )
        expect(id).toBe('def-new')
    })

    it('ensureFormDefinition reuses existing ID without patch', async () => {
        const searchFormDefinitionsByTenantV1 = vi.fn().mockResolvedValue({ data: { results: [{ id: 'def-existing' }] } })
        const createFormDefinitionV1 = vi.fn()
        const forms = { searchFormDefinitionsByTenantV1, createFormDefinitionV1, createFormInstanceV1: vi.fn() }

        const id = await ensureFormDefinition(forms, 'SOD Remediation', 'owner-1')

        expect(createFormDefinitionV1).not.toHaveBeenCalled()
        expect(id).toBe('def-existing')
    })

    it('createRemediationInstance sets standAloneForm, recipient, and formInput', async () => {
        const createFormInstanceV1 = vi.fn().mockResolvedValue({
            data: { standAloneFormUrl: 'https://tenant.identitynow.com/form/abc' },
        })
        const forms = {
            searchFormDefinitionsByTenantV1: vi.fn(),
            createFormDefinitionV1: vi.fn(),
            createFormInstanceV1,
        }

        const url = await createRemediationInstance({
            forms,
            formDefinitionId: 'def-1',
            recipientId: 'owner-1',
            createdBySourceId: 'source-1',
            formInput: {
                targetIdentityName: 'Alice',
                policyName: 'Policy',
                situationSummaryHtml: '<p>summary</p>',
                groupAOptions: [{ label: 'Ent A (Entitlement)', value: 'Ent A (Entitlement)' }],
                groupBOptions: [{ label: 'Ent B (Entitlement)', value: 'Ent B (Entitlement)' }],
                groupAWarning: 'warn',
                groupBWarning: 'warn',
                hasControls: true,
                violationId: 'vio-1',
                targetIdentityId: 'ident-1',
                groupARevokePayload: '{}',
                groupBRevokePayload: '{}',
            },
        })

        expect(createFormInstanceV1).toHaveBeenCalledWith(
            expect.objectContaining({
                body: expect.objectContaining({
                    standAloneForm: true,
                    state: 'ASSIGNED',
                    createdBy: { type: 'SOURCE', id: 'source-1' },
                    recipients: [{ id: 'owner-1', type: 'IDENTITY' }],
                    expire: expect.any(String),
                    formInput: expect.objectContaining({
                        hasControls: 'true',
                        groupAOptions: [{ label: 'Ent A (Entitlement)', value: 'Ent A (Entitlement)' }],
                    }),
                }),
            })
        )
        expect(url).toBe('https://tenant.identitynow.com/form/abc')
    })

    it('formatFormsApiError includes ISC response body and status', () => {
        const error = formatFormsApiError('Form instance create', {
            message: 'Request failed with status code 500',
            name: 'ApiError',
            status: 500,
            data: {
                detailCode: 'InternalError',
                messages: [{ text: 'form definition is invalid' }],
            },
        })

        expect(error).toBeInstanceOf(ConnectorError)
        expect(error.message).toContain('Form instance create failed with status 500')
        expect(error.message).toContain('form definition is invalid')
    })

    it('ensureFormDefinition surfaces search rejection as ConnectorError', async () => {
        const forms = {
            searchFormDefinitionsByTenantV1: vi.fn().mockRejectedValue(new Error('search failed')),
            createFormDefinitionV1: vi.fn(),
            createFormInstanceV1: vi.fn(),
        }

        await expect(ensureFormDefinition(forms, 'SOD Remediation', 'owner-1')).rejects.toBeInstanceOf(ConnectorError)
    })

    it('ensureFormDefinition throws ConnectorError when create returns no id', async () => {
        const forms = {
            searchFormDefinitionsByTenantV1: vi.fn().mockResolvedValue({ data: { results: [] } }),
            createFormDefinitionV1: vi.fn().mockResolvedValue({ data: {} }),
            createFormInstanceV1: vi.fn(),
        }

        await expect(ensureFormDefinition(forms, 'SOD Remediation', 'owner-1')).rejects.toThrow(
            /Failed to create form definition "SOD Remediation"/
        )
    })

    it('createRemediationInstance throws ConnectorError when standAloneFormUrl is missing', async () => {
        const forms = {
            searchFormDefinitionsByTenantV1: vi.fn(),
            createFormDefinitionV1: vi.fn(),
            createFormInstanceV1: vi.fn().mockResolvedValue({ data: {} }),
        }

        await expect(
            createRemediationInstance({
                forms,
                formDefinitionId: 'def-1',
                recipientId: 'owner-1',
                createdBySourceId: 'source-1',
                formInput: {
                    targetIdentityName: 'Alice',
                    policyName: 'Policy',
                    situationSummaryHtml: '<p>summary</p>',
                    groupAOptions: [{ label: 'Ent A (Entitlement)', value: 'Ent A (Entitlement)' }],
                    groupBOptions: [{ label: 'Ent B (Entitlement)', value: 'Ent B (Entitlement)' }],
                    groupAWarning: 'warn',
                    groupBWarning: 'warn',
                    hasControls: true,
                    violationId: 'vio-1',
                    targetIdentityId: 'ident-1',
                    groupARevokePayload: '{}',
                    groupBRevokePayload: '{}',
                },
            })
        ).rejects.toBeInstanceOf(ConnectorError)
    })

    it('createRemediationInstance surfaces ISC error body on API failure', async () => {
        const createFormInstanceV1 = vi.fn().mockRejectedValue({
            message: 'Request failed with status code 500',
            name: 'ApiError',
            status: 500,
            data: {
                detailCode: 'InternalError',
                messages: [{ text: 'recipient not found' }],
            },
        })
        const forms = {
            searchFormDefinitionsByTenantV1: vi.fn(),
            createFormDefinitionV1: vi.fn(),
            createFormInstanceV1,
        }

        await expect(
            createRemediationInstance({
                forms,
                formDefinitionId: 'def-1',
                recipientId: 'owner-1',
                createdBySourceId: 'source-1',
                formInput: {
                    targetIdentityName: 'Alice',
                    policyName: 'Policy',
                    situationSummaryHtml: '<p>summary</p>',
                    groupAOptions: [{ label: 'Ent A (Entitlement)', value: 'Ent A (Entitlement)' }],
                    groupBOptions: [{ label: 'Ent B (Entitlement)', value: 'Ent B (Entitlement)' }],
                    groupAWarning: 'warn',
                    groupBWarning: 'warn',
                    hasControls: true,
                    violationId: 'vio-1',
                    targetIdentityId: 'ident-1',
                    groupARevokePayload: '{}',
                    groupBRevokePayload: '{}',
                },
            })
        ).rejects.toThrow(/recipient not found/)
    })
})


