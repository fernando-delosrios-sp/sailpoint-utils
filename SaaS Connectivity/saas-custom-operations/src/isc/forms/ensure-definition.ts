import { ConnectorError } from '@sailpoint/connector-sdk'
import { CustomFormsApi } from 'sailpoint-api-client'
import { callFormsApi } from './error-formatting'
import { CreateFormDefinitionPayload } from './seed-loader'
import { computeFormSeedFingerprint, parseFormSeedWatermark } from './seed-watermark'

export interface FormsApiLike {
    searchFormDefinitionsByTenantV1: CustomFormsApi['searchFormDefinitionsByTenantV1']
    getFormDefinitionByKeyV1: CustomFormsApi['getFormDefinitionByKeyV1']
    createFormDefinitionV1: CustomFormsApi['createFormDefinitionV1']
    patchFormDefinitionV1: CustomFormsApi['patchFormDefinitionV1']
    createFormInstanceV1: CustomFormsApi['createFormInstanceV1']
}

export interface EnsureFormDefinitionParams {
    name: string
    ownerId: string
    template: CreateFormDefinitionPayload
}

function buildFormDefinitionPatchBody(template: CreateFormDefinitionPayload): Array<{ op: string; path: string; value: unknown }> {
    return [
        { op: 'replace', path: '/description', value: template.description },
        { op: 'replace', path: '/formInput', value: template.formInput },
        { op: 'replace', path: '/formElements', value: template.formElements },
        { op: 'replace', path: '/formConditions', value: template.formConditions ?? [] },
    ]
}

function templateFingerprint(template: CreateFormDefinitionPayload): string {
    return computeFormSeedFingerprint({
        formInput: template.formInput,
        formElements: template.formElements,
        formConditions: template.formConditions,
    })
}

/**
 * Ensures a tenant form definition exists and matches the bundled seed fingerprint.
 * Reuses when the description watermark matches; patches when stale or missing; creates when absent.
 */
export async function ensureFormDefinitionByName(
    forms: FormsApiLike,
    params: EnsureFormDefinitionParams
): Promise<string> {
    const { name, template } = params
    const expectedFingerprint = templateFingerprint(template)

    const searchResponse = await callFormsApi('Form definition search', () =>
        forms.searchFormDefinitionsByTenantV1({
            filters: `name eq "${name}"`,
        })
    )

    const existing = searchResponse.data?.results?.[0]
    if (!existing?.id) {
        return createFormDefinition(forms, name, template)
    }

    const definitionId = existing.id

    const getResponse = await callFormsApi('Form definition read', () =>
        forms.getFormDefinitionByKeyV1({ formDefinitionID: definitionId })
    )
    const existingDescription = getResponse.data?.description
    const existingFingerprint = parseFormSeedWatermark(existingDescription)

    if (existingFingerprint === expectedFingerprint) {
        return definitionId
    }

    await callFormsApi('Form definition patch', () =>
        forms.patchFormDefinitionV1({
            formDefinitionID: definitionId,
            body: buildFormDefinitionPatchBody(template) as never,
        })
    )
    return definitionId
}

async function createFormDefinition(
    forms: FormsApiLike,
    name: string,
    template: CreateFormDefinitionPayload
): Promise<string> {
    const createResponse = await callFormsApi('Form definition create', () =>
        forms.createFormDefinitionV1({
            body: template as never,
        })
    )
    const definitionId = createResponse.data?.id
    if (!definitionId) {
        throw new ConnectorError(`Failed to create form definition "${name}"`)
    }
    return definitionId
}
