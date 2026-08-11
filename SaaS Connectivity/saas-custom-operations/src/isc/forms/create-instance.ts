import { ConnectorError } from '@sailpoint/connector-sdk'
import { callFormsApi } from './error-formatting'
import { FormsApiLike } from './ensure-definition'

const FORM_INSTANCE_TTL_DAYS = 30

function defaultFormExpire(): string {
    return new Date(Date.now() + FORM_INSTANCE_TTL_DAYS * 24 * 60 * 60 * 1000).toISOString()
}

export interface CreateStandaloneFormInstanceParams {
    forms: FormsApiLike
    formDefinitionId: string
    recipientId: string
    createdBySourceId: string
    formInput: Record<string, unknown>
    expire?: string
}

/** Creates a standalone assigned form instance and returns standAloneFormUrl. */
export async function createStandaloneFormInstance(params: CreateStandaloneFormInstanceParams): Promise<string> {
    const { forms, formDefinitionId, recipientId, createdBySourceId, formInput, expire } = params
    const requestBody = {
        formDefinitionId,
        recipients: [{ id: recipientId, type: 'IDENTITY' }],
        standAloneForm: true,
        state: 'ASSIGNED',
        createdBy: { type: 'SOURCE', id: createdBySourceId },
        expire: expire ?? defaultFormExpire(),
        formInput: formInput as never,
    }
    const response = await callFormsApi('Form instance create', () =>
        forms.createFormInstanceV1({ body: requestBody as never })
    )

    const instanceState = response.data?.state
    if (instanceState && instanceState !== 'ASSIGNED' && instanceState !== 'IN_PROGRESS') {
        throw new ConnectorError(`Form instance create returned unexpected state: ${instanceState}`)
    }

    const formUrl = response.data?.standAloneFormUrl
    if (!formUrl) {
        throw new ConnectorError('Form instance create did not return standAloneFormUrl')
    }
    return formUrl
}
