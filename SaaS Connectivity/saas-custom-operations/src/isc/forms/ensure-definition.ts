import { ConnectorError } from '@sailpoint/connector-sdk'
import { CustomFormsApi } from 'sailpoint-api-client'
import { callFormsApi } from './error-formatting'
import { CreateFormDefinitionPayload } from './seed-loader'

export interface FormsApiLike {
    searchFormDefinitionsByTenantV1: CustomFormsApi['searchFormDefinitionsByTenantV1']
    createFormDefinitionV1: CustomFormsApi['createFormDefinitionV1']
    createFormInstanceV1: CustomFormsApi['createFormInstanceV1']
}

export interface EnsureFormDefinitionParams {
    name: string
    ownerId: string
    template: CreateFormDefinitionPayload
}

/** Searches for a form definition by name; creates from caller template when absent. Never patches existing definitions. */
export async function ensureFormDefinitionByName(
    forms: FormsApiLike,
    params: EnsureFormDefinitionParams
): Promise<string> {
    const { name, template } = params

    const searchResponse = await callFormsApi('Form definition search', () =>
        forms.searchFormDefinitionsByTenantV1({
            filters: `name eq "${name}"`,
        })
    )

    const existing = searchResponse.data?.results?.[0]
    if (existing?.id) {
        return existing.id
    }

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
