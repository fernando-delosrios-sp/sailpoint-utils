import { CustomFormsApi } from 'sailpoint-api-client'
import { buildFormDefinitionFromSeed } from './form-seed-loader'

export interface FormsApiLike {
    searchFormDefinitionsByTenantV1: CustomFormsApi['searchFormDefinitionsByTenantV1']
    createFormDefinitionV1: CustomFormsApi['createFormDefinitionV1']
    createFormInstanceV1: CustomFormsApi['createFormInstanceV1']
}

export interface SodFormInputValues {
    targetIdentityName: string
    policyName: string
    situationSummaryHtml: string
    groupADisplay: string
    groupBDisplay: string
    groupAWarning: string
    groupBWarning: string
    hasControls: boolean
    violationId: string
    targetIdentityId: string
    groupARevokePayload: string
    groupBRevokePayload: string
}

const FORM_INSTANCE_TTL_DAYS = 30

function defaultFormExpire(): string {
    return new Date(Date.now() + FORM_INSTANCE_TTL_DAYS * 24 * 60 * 60 * 1000).toISOString()
}

/** Searches for a form definition by name; creates from seed when absent. Never patches existing definitions. */
export async function ensureFormDefinition(forms: FormsApiLike, formName: string, ownerId: string): Promise<string> {
    const searchResponse = await forms.searchFormDefinitionsByTenantV1({
        filters: `name eq "${formName}"`,
    })

    const existing = searchResponse.data?.results?.[0]
    if (existing?.id) {
        return existing.id
    }

    const createResponse = await forms.createFormDefinitionV1({
        body: buildFormDefinitionFromSeed(formName, ownerId) as never,
    })
    const definitionId = createResponse.data?.id
    if (!definitionId) {
        throw new Error(`Failed to create form definition "${formName}"`)
    }
    return definitionId
}

export interface CreateRemediationInstanceParams {
    forms: FormsApiLike
    formDefinitionId: string
    recipientId: string
    createdBySourceId: string
    formInput: SodFormInputValues
}

/** Creates a standalone assigned form instance for the remediation recipient. */
export async function createRemediationInstance(params: CreateRemediationInstanceParams): Promise<string> {
    const { forms, formDefinitionId, recipientId, createdBySourceId, formInput } = params
    const requestBody = {
        formDefinitionId,
        recipients: [{ id: recipientId, type: 'IDENTITY' }],
        standAloneForm: true,
        state: 'ASSIGNED',
        createdBy: { type: 'SOURCE', id: createdBySourceId },
        expire: defaultFormExpire(),
        formInput: {
            ...formInput,
            hasControls: String(formInput.hasControls),
        } as never,
    }
    const response = await forms.createFormInstanceV1({ body: requestBody as never })

    const formUrl = response.data?.standAloneFormUrl
    if (!formUrl) {
        throw new Error('Form instance create did not return standAloneFormUrl')
    }
    return formUrl
}

/** Converts structured form input values to the ISC formInput map. */
export function toFormInputMap(values: SodFormInputValues): Record<string, unknown> {
    return { ...values }
}
