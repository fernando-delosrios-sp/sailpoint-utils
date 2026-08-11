import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { resolve } from 'path'
import { createStandaloneFormInstance } from './create-instance'
import { ensureFormDefinitionByName } from './ensure-definition'
import { formatFormsApiError } from './error-formatting'
import { buildCreateFormDefinitionPayload, loadFormSeed } from './seed-loader'

const seedPath = resolve(__dirname, '../../operations/sod-remediation/seed/sod-violation-remediation.seed.json')

describe('isc/forms seed-loader', () => {
    it('loadFormSeed reads caller-supplied seed path', () => {
        const seed = loadFormSeed(seedPath)
        expect(seed.formElements.length).toBeGreaterThan(0)
        expect(seed.formInput?.some((input) => input.id === 'violationId')).toBe(true)
    })

    it('buildCreateFormDefinitionPayload applies runtime form name and owner', () => {
        const seed = loadFormSeed(seedPath)
        const payload = buildCreateFormDefinitionPayload('Tenant SOD Form', 'owner-abc', seed)

        expect(payload.name).toBe('Tenant SOD Form')
        expect(payload.owner).toEqual({ type: 'IDENTITY', id: 'owner-abc' })
        expect(payload.formElements.length).toBeGreaterThan(0)
    })
})

describe('isc/forms ensure-definition', () => {
    it('ensureFormDefinitionByName searches tenant and creates from template when missing', async () => {
        const searchFormDefinitionsByTenantV1 = vi.fn().mockResolvedValue({ data: { results: [] } })
        const createFormDefinitionV1 = vi.fn().mockResolvedValue({ data: { id: 'def-new' } })
        const forms = { searchFormDefinitionsByTenantV1, createFormDefinitionV1, createFormInstanceV1: vi.fn() }
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)

        const id = await ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })

        expect(searchFormDefinitionsByTenantV1).toHaveBeenCalledWith({ filters: 'name eq "SOD Remediation"' })
        expect(createFormDefinitionV1).toHaveBeenCalledWith(
            expect.objectContaining({ body: expect.objectContaining({ name: 'SOD Remediation', owner: { type: 'IDENTITY', id: 'owner-1' } }) })
        )
        expect(id).toBe('def-new')
    })

    it('ensureFormDefinitionByName reuses existing ID without patch', async () => {
        const searchFormDefinitionsByTenantV1 = vi.fn().mockResolvedValue({ data: { results: [{ id: 'def-existing' }] } })
        const createFormDefinitionV1 = vi.fn()
        const forms = { searchFormDefinitionsByTenantV1, createFormDefinitionV1, createFormInstanceV1: vi.fn() }
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)

        const id = await ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })

        expect(createFormDefinitionV1).not.toHaveBeenCalled()
        expect(id).toBe('def-existing')
    })

    it('ensureFormDefinitionByName surfaces search rejection as ConnectorError', async () => {
        const forms = {
            searchFormDefinitionsByTenantV1: vi.fn().mockRejectedValue(new Error('search failed')),
            createFormDefinitionV1: vi.fn(),
            createFormInstanceV1: vi.fn(),
        }
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)

        await expect(
            ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })
        ).rejects.toBeInstanceOf(ConnectorError)
    })

    it('ensureFormDefinitionByName throws ConnectorError when create returns no id', async () => {
        const forms = {
            searchFormDefinitionsByTenantV1: vi.fn().mockResolvedValue({ data: { results: [] } }),
            createFormDefinitionV1: vi.fn().mockResolvedValue({ data: {} }),
            createFormInstanceV1: vi.fn(),
        }
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)

        await expect(
            ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })
        ).rejects.toThrow(/Failed to create form definition "SOD Remediation"/)
    })
})

describe('isc/forms create-instance', () => {
    it('createStandaloneFormInstance sets standAloneForm, recipient, and formInput', async () => {
        const createFormInstanceV1 = vi.fn().mockResolvedValue({
            data: { standAloneFormUrl: 'https://tenant.identitynow.com/form/abc' },
        })
        const forms = {
            searchFormDefinitionsByTenantV1: vi.fn(),
            createFormDefinitionV1: vi.fn(),
            createFormInstanceV1,
        }

        const url = await createStandaloneFormInstance({
            forms,
            formDefinitionId: 'def-1',
            recipientId: 'owner-1',
            createdBySourceId: 'source-1',
            formInput: { summary: 'example', hasControls: 'true' },
        })

        expect(createFormInstanceV1).toHaveBeenCalledWith(
            expect.objectContaining({
                body: expect.objectContaining({
                    standAloneForm: true,
                    state: 'ASSIGNED',
                    createdBy: { type: 'SOURCE', id: 'source-1' },
                    recipients: [{ id: 'owner-1', type: 'IDENTITY' }],
                    expire: expect.any(String),
                    formInput: { summary: 'example', hasControls: 'true' },
                }),
            })
        )
        expect(url).toBe('https://tenant.identitynow.com/form/abc')
    })

    it('createStandaloneFormInstance throws ConnectorError when standAloneFormUrl is missing', async () => {
        const forms = {
            searchFormDefinitionsByTenantV1: vi.fn(),
            createFormDefinitionV1: vi.fn(),
            createFormInstanceV1: vi.fn().mockResolvedValue({ data: {} }),
        }

        await expect(
            createStandaloneFormInstance({
                forms,
                formDefinitionId: 'def-1',
                recipientId: 'owner-1',
                createdBySourceId: 'source-1',
                formInput: {},
            })
        ).rejects.toBeInstanceOf(ConnectorError)
    })
})

describe('isc/forms error-formatting', () => {
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
})
