import { ConnectorError } from '@sailpoint/connector-sdk'
import { CustomFormsApi } from 'sailpoint-api-client'
import { buildFormDefinitionFromSeed } from './form-seed-loader'

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

/** Maps sailpoint-api-client / axios Forms API errors into a message that includes the ISC response body. */
export function formatFormsApiError(operation: string, error: unknown): ConnectorError {
    if (isRecord(error)) {
        const status = typeof error.status === 'number' ? error.status : undefined
        const body = 'data' in error ? error.data : undefined

        if (status !== undefined || body !== undefined) {
            const statusSuffix = status !== undefined ? ` with status ${status}` : ''
            const bodyText =
                body === undefined
                    ? String(error.message ?? 'unknown error')
                    : typeof body === 'string'
                      ? body
                      : JSON.stringify(body)
            return new ConnectorError(`${operation} failed${statusSuffix}: ${bodyText}`)
        }

        if (isRecord(error.response)) {
            const axiosStatus = error.response.status
            const axiosBody = error.response.data
            const statusSuffix = typeof axiosStatus === 'number' ? ` with status ${axiosStatus}` : ''
            const bodyText =
                axiosBody === undefined
                    ? String(error.message ?? 'unknown error')
                    : typeof axiosBody === 'string'
                      ? axiosBody
                      : JSON.stringify(axiosBody)
            return new ConnectorError(`${operation} failed${statusSuffix}: ${bodyText}`)
        }
    }

    if (error instanceof Error) {
        return new ConnectorError(`${operation} failed: ${error.message}`)
    }

    return new ConnectorError(`${operation} failed: ${String(error)}`)
}

async function callFormsApi<T>(operation: string, fn: () => Promise<T>): Promise<T> {
    try {
        return await fn()
    } catch (error) {
        throw formatFormsApiError(operation, error)
    }
}

export interface FormsApiLike {
    searchFormDefinitionsByTenantV1: CustomFormsApi['searchFormDefinitionsByTenantV1']
    createFormDefinitionV1: CustomFormsApi['createFormDefinitionV1']
    createFormInstanceV1: CustomFormsApi['createFormInstanceV1']
}

export interface FormInputSelectOption {
    label: string
    value: string
    sublabel?: string
}

export interface SodFormInputValues {
    targetIdentityName: string
    policyName: string
    situationSummaryHtml: string
    groupAOptions: FormInputSelectOption[]
    groupBOptions: FormInputSelectOption[]
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
    const searchResponse = await callFormsApi('Form definition search', () =>
        forms.searchFormDefinitionsByTenantV1({
            filters: `name eq "${formName}"`,
        })
    )

    const existing = searchResponse.data?.results?.[0]
    if (existing?.id) {
        return existing.id
    }

    const createResponse = await callFormsApi('Form definition create', () =>
        forms.createFormDefinitionV1({
            body: buildFormDefinitionFromSeed(formName, ownerId) as never,
        })
    )
    const definitionId = createResponse.data?.id
    if (!definitionId) {
        throw new ConnectorError(`Failed to create form definition "${formName}"`)
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
    const response = await callFormsApi('Form instance create', () =>
        forms.createFormInstanceV1({ body: requestBody as never })
    )

    const formUrl = response.data?.standAloneFormUrl
    if (!formUrl) {
        throw new ConnectorError('Form instance create did not return standAloneFormUrl')
    }
    return formUrl
}

/** Converts structured form input values to the ISC formInput map. */
export function toFormInputMap(values: SodFormInputValues): Record<string, unknown> {
    return { ...values }
}

