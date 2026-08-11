import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { resolve } from 'path'
import { createStandaloneFormInstance } from './create-instance'
import { ensureFormDefinitionByName } from './ensure-definition'
import { formatFormsApiError } from './error-formatting'
import { buildCreateFormDefinitionPayload, loadFormSeed } from './seed-loader'
import {
    computeFormSeedFingerprint,
    formatWatermarkedDescription,
    FORM_SEED_WATERMARK_PREFIX,
    parseFormSeedWatermark,
} from './seed-watermark'

const seedPath = resolve(__dirname, '../../operations/sod-remediation/seed/sod-violation-remediation.seed.json')

function createFormsStub(overrides: Record<string, unknown> = {}) {
    return {
        searchFormDefinitionsByTenantV1: vi.fn(),
        getFormDefinitionByKeyV1: vi.fn(),
        createFormDefinitionV1: vi.fn(),
        patchFormDefinitionV1: vi.fn(),
        createFormInstanceV1: vi.fn(),
        ...overrides,
    }
}

describe('isc/forms seed-watermark', () => {
    it('computeFormSeedFingerprint is stable for the same seed', () => {
        const seed = loadFormSeed(seedPath)
        expect(computeFormSeedFingerprint(seed)).toBe(computeFormSeedFingerprint(seed))
    })

    it('computeFormSeedFingerprint changes when formElements change', () => {
        const seed = loadFormSeed(seedPath)
        const altered = {
            ...seed,
            formElements: [...seed.formElements, { id: 'extra', elementType: 'TEXT', key: 'extra', config: { label: 'Extra' } }],
        }
        expect(computeFormSeedFingerprint(altered)).not.toBe(computeFormSeedFingerprint(seed))
    })

    it('formatWatermarkedDescription prefixes fingerprint and preserves human text', () => {
        const formatted = formatWatermarkedDescription('abc123', 'Example remediation form')
        expect(formatted).toBe(`${FORM_SEED_WATERMARK_PREFIX}abc123\nExample remediation form`)
    })

    it('parseFormSeedWatermark extracts fingerprint from first line', () => {
        const fingerprint = 'a'.repeat(64)
        expect(parseFormSeedWatermark(`${FORM_SEED_WATERMARK_PREFIX}${fingerprint}\nHuman text`)).toBe(fingerprint)
    })

    it('parseFormSeedWatermark returns undefined for legacy descriptions', () => {
        expect(parseFormSeedWatermark('SOD violation remediation form')).toBeUndefined()
        expect(parseFormSeedWatermark(undefined)).toBeUndefined()
        expect(parseFormSeedWatermark(`${FORM_SEED_WATERMARK_PREFIX}abc123`)).toBeUndefined()
    })
})

describe('isc/forms seed-loader', () => {
    it('loadFormSeed reads caller-supplied seed path', () => {
        const seed = loadFormSeed(seedPath)
        expect(seed.formElements.length).toBeGreaterThan(0)
        expect(seed.formInput?.some((input) => input.id === 'violationId')).toBe(true)
    })

    it('loadFormSeed accepts bundled seed object', () => {
        const seed = loadFormSeed(loadFormSeed(seedPath))
        expect(seed.formElements.length).toBeGreaterThan(0)
    })

    it('loadFormSeed rejects bundled seed without formElements', () => {
        expect(() => loadFormSeed({ formInput: [] })).toThrow(/missing formElements/)
    })

    it('buildCreateFormDefinitionPayload applies runtime form name, owner, and watermark', () => {
        const seed = loadFormSeed(seedPath)
        const payload = buildCreateFormDefinitionPayload('Tenant SOD Form', 'owner-abc', seed)
        const fingerprint = computeFormSeedFingerprint(seed)

        expect(payload.name).toBe('Tenant SOD Form')
        expect(payload.owner).toEqual({ type: 'IDENTITY', id: 'owner-abc' })
        expect(payload.formElements.length).toBeGreaterThan(0)
        expect(payload.description).toBe(formatWatermarkedDescription(fingerprint, seed.description))
    })

    it('buildCreateFormDefinitionPayload uses watermark-only description when seed has no human text', () => {
        const seed = {
            formInput: [],
            formElements: [{ id: 'field-1', elementType: 'TEXT', key: 'field1', config: { label: 'Field 1' } }],
        }
        const payload = buildCreateFormDefinitionPayload('Minimal Form', 'owner-abc', seed)
        const fingerprint = computeFormSeedFingerprint(seed)

        expect(payload.description).toBe(`${FORM_SEED_WATERMARK_PREFIX}${fingerprint}`)
        expect(payload.description).not.toContain('\n')
    })
})

describe('isc/forms ensure-definition', () => {
    it('ensureFormDefinitionByName searches tenant and creates from template when missing', async () => {
        const forms = createFormsStub({
            searchFormDefinitionsByTenantV1: vi.fn().mockResolvedValue({ data: { results: [] } }),
            createFormDefinitionV1: vi.fn().mockResolvedValue({ data: { id: 'def-new' } }),
        })
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)

        const id = await ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })

        expect(forms.searchFormDefinitionsByTenantV1).toHaveBeenCalledWith({ filters: 'name eq "SOD Remediation"' })
        expect(forms.createFormDefinitionV1).toHaveBeenCalledWith(
            expect.objectContaining({ body: expect.objectContaining({ name: 'SOD Remediation', owner: { type: 'IDENTITY', id: 'owner-1' } }) })
        )
        expect(forms.getFormDefinitionByKeyV1).not.toHaveBeenCalled()
        expect(id).toBe('def-new')
    })

    it('ensureFormDefinitionByName reuses existing ID when watermark matches', async () => {
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)
        const forms = createFormsStub({
            searchFormDefinitionsByTenantV1: vi.fn().mockResolvedValue({ data: { results: [{ id: 'def-existing' }] } }),
            getFormDefinitionByKeyV1: vi.fn().mockResolvedValue({ data: { id: 'def-existing', description: template.description } }),
        })

        const id = await ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })

        expect(forms.createFormDefinitionV1).not.toHaveBeenCalled()
        expect(forms.patchFormDefinitionV1).not.toHaveBeenCalled()
        expect(id).toBe('def-existing')
    })

    it('ensureFormDefinitionByName patches stale watermark and returns existing id', async () => {
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)
        const forms = createFormsStub({
            searchFormDefinitionsByTenantV1: vi.fn().mockResolvedValue({ data: { results: [{ id: 'def-existing' }] } }),
            getFormDefinitionByKeyV1: vi.fn().mockResolvedValue({
                data: { id: 'def-existing', description: 'Legacy description without watermark' },
            }),
            patchFormDefinitionV1: vi.fn().mockResolvedValue({ data: { id: 'def-existing' } }),
        })

        const id = await ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })

        expect(forms.patchFormDefinitionV1).toHaveBeenCalledWith({
            formDefinitionID: 'def-existing',
            body: expect.arrayContaining([
                expect.objectContaining({ op: 'replace', path: '/description', value: template.description }),
                expect.objectContaining({ op: 'replace', path: '/formElements', value: template.formElements }),
            ]),
        })
        expect(forms.createFormDefinitionV1).not.toHaveBeenCalled()
        expect(id).toBe('def-existing')
    })

    it('ensureFormDefinitionByName surfaces search rejection as ConnectorError', async () => {
        const forms = createFormsStub({
            searchFormDefinitionsByTenantV1: vi.fn().mockRejectedValue(new Error('search failed')),
        })
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)

        await expect(
            ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })
        ).rejects.toBeInstanceOf(ConnectorError)
    })

    it('ensureFormDefinitionByName surfaces get rejection as ConnectorError', async () => {
        const forms = createFormsStub({
            searchFormDefinitionsByTenantV1: vi.fn().mockResolvedValue({ data: { results: [{ id: 'def-existing' }] } }),
            getFormDefinitionByKeyV1: vi.fn().mockRejectedValue(new Error('get failed')),
        })
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)

        await expect(
            ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })
        ).rejects.toBeInstanceOf(ConnectorError)
    })

    it('ensureFormDefinitionByName surfaces patch rejection as ConnectorError', async () => {
        const seed = loadFormSeed(seedPath)
        const template = buildCreateFormDefinitionPayload('SOD Remediation', 'owner-1', seed)
        const forms = createFormsStub({
            searchFormDefinitionsByTenantV1: vi.fn().mockResolvedValue({ data: { results: [{ id: 'def-existing' }] } }),
            getFormDefinitionByKeyV1: vi.fn().mockResolvedValue({
                data: { id: 'def-existing', description: 'Legacy description without watermark' },
            }),
            patchFormDefinitionV1: vi.fn().mockRejectedValue(new Error('patch failed')),
        })

        await expect(
            ensureFormDefinitionByName(forms, { name: 'SOD Remediation', ownerId: 'owner-1', template })
        ).rejects.toBeInstanceOf(ConnectorError)
    })

    it('ensureFormDefinitionByName throws ConnectorError when create returns no id', async () => {
        const forms = createFormsStub({
            searchFormDefinitionsByTenantV1: vi.fn().mockResolvedValue({ data: { results: [] } }),
            createFormDefinitionV1: vi.fn().mockResolvedValue({ data: {} }),
        })
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
        const forms = createFormsStub({ createFormInstanceV1 })

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
        const forms = createFormsStub({
            createFormInstanceV1: vi.fn().mockResolvedValue({ data: {} }),
        })

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
