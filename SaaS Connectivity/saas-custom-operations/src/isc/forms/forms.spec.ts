import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { resolve } from 'path'
import { createStandaloneFormInstance } from './create-instance'
import { ensureFormDefinitionByName } from './ensure-definition'
import { formatFormsApiError } from './error-formatting'
import { buildCreateFormDefinitionPayload, loadFormSeed } from './seed-loader'
import { pickDeclaredFormInputValues } from './form-input-values'
import {
    computeFormSeedFingerprint,
    formatWatermarkedDescription,
    FORM_SEED_WATERMARK_PREFIX,
    parseFormSeedWatermark,
} from './seed-watermark'

const seedPath = resolve(__dirname, '../../operations/sod-remediation/seed/sod-violation-remediation.seed.json')
const accessModelSodSeedPath = resolve(
    __dirname,
    '../../operations/access-model-sod-remediation/seed/access-model-sod-remediation.seed.json'
)

function collectDescriptionElements(elements: Array<Record<string, unknown>>): Array<Record<string, unknown>> {
    const descriptions: Array<Record<string, unknown>> = []
    for (const element of elements) {
        if (element.elementType === 'DESCRIPTION') {
            descriptions.push(element)
        }
        const config = element.config as Record<string, unknown> | undefined
        const nested = (config?.formElements ?? config?.columns) as Array<Record<string, unknown>> | undefined
        if (Array.isArray(nested)) {
            descriptions.push(...collectDescriptionElements(nested))
        }
        if (Array.isArray(config?.columns)) {
            for (const column of config.columns as Array<Array<Record<string, unknown>>>) {
                descriptions.push(...collectDescriptionElements(column))
            }
        }
    }
    return descriptions
}

function findFormElementById(
    elements: Array<Record<string, unknown>>,
    id: string
): Record<string, unknown> | undefined {
    for (const element of elements) {
        if (element.id === id) {
            return element
        }
        const config = element.config as Record<string, unknown> | undefined
        const nested = config?.formElements as Array<Record<string, unknown>> | undefined
        if (Array.isArray(nested)) {
            const match = findFormElementById(nested, id)
            if (match) {
                return match
            }
        }
    }
    return undefined
}

function collectNestedSectionViolations(elements: Array<Record<string, unknown>>): string[] {
    const violations: string[] = []
    for (const element of elements) {
        if (element.elementType !== 'SECTION') {
            continue
        }
        const config = element.config as Record<string, unknown> | undefined
        const nested = (config?.formElements ?? []) as Array<Record<string, unknown>>
        for (const child of nested) {
            if (child.elementType === 'SECTION') {
                violations.push(`${String(element.id)} contains nested SECTION ${String(child.id)}`)
            }
        }
        violations.push(...collectNestedSectionViolations(nested))
    }
    return violations
}

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
        expect(seed.formInput?.some((input) => input.id === 'hasControls')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'violationId')).toBe(true)
    })

    it('loadFormSeed accepts bundled seed object', () => {
        const seed = loadFormSeed(loadFormSeed(seedPath))
        expect(seed.formElements.length).toBeGreaterThan(0)
    })

    it('loadFormSeed rejects bundled seed without formElements', () => {
        expect(() => loadFormSeed({ formInput: [] })).toThrow(/missing formElements/)
    })

    it('pickDeclaredFormInputValues drops undeclared keys and normalizes controlOptions', () => {
        const seed = loadFormSeed(seedPath)
        const picked = pickDeclaredFormInputValues(seed, {
            violationId: 'vio-1',
            recommendedSideToCorrect: 'groupA',
            hasControls: 'true',
            controlOptions: [{ label: 'Control 1', value: 'ctrl-1', sublabel: undefined }],
        })

        expect(picked.violationId).toBe('vio-1')
        expect(picked.hasControls).toBe('true')
        expect(picked).not.toHaveProperty('recommendedSideToCorrect')
        expect(picked.controlOptions).toEqual([{ label: 'Control 1', value: 'ctrl-1' }])
    })

    it('pickDeclaredFormInputValues passes STRING group id fields through for access-model-sod-remediation seed', () => {
        const seed = loadFormSeed(accessModelSodSeedPath)
        const picked = pickDeclaredFormInputValues(seed, {
            accessItemId: 'role-1',
            groupAIds: '["ent-a","ent-b"]',
            groupBIds: '["ent-c"]',
            extraKey: 'ignored',
        })

        expect(picked.groupAIds).toBe('["ent-a","ent-b"]')
        expect(picked.groupBIds).toBe('["ent-c"]')
        expect(picked).not.toHaveProperty('extraKey')
    })

    it('access-model-sod-remediation seed context panel uses pre-rendered type tag HTML', () => {
        const seed = loadFormSeed(accessModelSodSeedPath)
        const ctxItem = findFormElementById(seed.formElements as Array<Record<string, unknown>>, 'ctx-item')
        const description = (ctxItem?.config as { description?: string })?.description ?? ''

        expect(seed.formInput?.some((field) => field.id === 'accessItemTypeTagHtml')).toBe(true)
        expect(description).toContain('{{$.form.input.accessItemTypeTagHtml}}')
        expect(description).not.toContain('#546e7a')
        expect(description).not.toContain('accessItemType}}')
    })

    it('access-model-sod-remediation seed swaps column previews via ELEMENT SHOW conditions on remediationSide', () => {
        const seed = loadFormSeed(accessModelSodSeedPath)

        expect(findFormElementById(seed.formElements, 'group-columns-plain')?.elementType).toBe('DESCRIPTION')
        expect(findFormElementById(seed.formElements, 'group-columns-when-a-removed')?.elementType).toBe('DESCRIPTION')
        expect(findFormElementById(seed.formElements, 'group-columns-when-b-removed')?.elementType).toBe('DESCRIPTION')
        expect(findFormElementById(seed.formElements, 'group-columns-preview')).toBeUndefined()

        const conditions = seed.formConditions ?? []
        expect(conditions).toHaveLength(3)

        for (const condition of conditions) {
            const rules = (condition.rules as Array<Record<string, unknown>>) ?? []
            expect(rules.every((rule) => rule.sourceType === 'ELEMENT' && rule.source === 'remediationSide')).toBe(true)
            const effects = (condition.effects as Array<Record<string, unknown>>) ?? []
            expect(effects.every((effect) => effect.effectType === 'SHOW')).toBe(true)
        }

        const showTargets = conditions.flatMap((condition) =>
            ((condition.effects as Array<{ config?: { element?: string } }>) ?? []).map((effect) => effect.config?.element)
        )
        expect(showTargets).toEqual([
            'group-columns-plain',
            'group-columns-when-a-removed',
            'group-columns-when-b-removed',
        ])

        const eqValues = conditions.flatMap((condition) =>
            ((condition.rules as Array<{ operator?: string; value?: string }>) ?? [])
                .filter((rule) => rule.operator === 'EQ')
                .map((rule) => rule.value)
        )
        expect(eqValues).toEqual(['Group A', 'Group B'])
    })

    it.each([
        ['sod-remediation', seedPath],
        ['access-model-sod-remediation', accessModelSodSeedPath],
    ])('%s seed wraps all root form elements in SECTION', (_name, path) => {
        const seed = loadFormSeed(path)

        for (const element of seed.formElements ?? []) {
            expect(element.elementType, String(element.id)).toBe('SECTION')
        }
    })

    it.each([
        ['sod-remediation', seedPath],
        ['access-model-sod-remediation', accessModelSodSeedPath],
    ])('%s seed does not nest SECTION inside SECTION', (_name, path) => {
        const seed = loadFormSeed(path)
        expect(collectNestedSectionViolations(seed.formElements as Array<Record<string, unknown>>)).toEqual([])
    })

    it.each([
        ['sod-remediation', seedPath],
        ['access-model-sod-remediation', accessModelSodSeedPath],
    ])('%s seed DESCRIPTION elements require non-empty labels', (_name, path) => {
        const seed = loadFormSeed(path)
        const descriptions = collectDescriptionElements(seed.formElements as Array<Record<string, unknown>>)

        expect(descriptions.length).toBeGreaterThan(0)
        for (const element of descriptions) {
            const label = (element.config as { label?: string })?.label
            expect(label, String(element.id)).toBeTruthy()
        }
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

    it('createStandaloneFormInstance rejects unexpected initial state', async () => {
        const forms = createFormsStub({
            createFormInstanceV1: vi.fn().mockResolvedValue({
                data: { standAloneFormUrl: 'https://tenant.identitynow.com/form/abc', state: 'SUBMITTED' },
            }),
        })

        await expect(
            createStandaloneFormInstance({
                forms,
                formDefinitionId: 'def-1',
                recipientId: 'owner-1',
                createdBySourceId: 'source-1',
                formInput: {},
            })
        ).rejects.toThrow(/unexpected state: SUBMITTED/)
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
