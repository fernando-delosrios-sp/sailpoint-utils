import { ConnectorError } from '@sailpoint/connector-sdk'
import { escapeODataString } from '../accounts'
import { callFormsApi } from './error-formatting'
import { FormsApiLike } from './ensure-definition'
import { normalizeFormInstance, NormalizedFormInstance } from './get-form-instance'

export const FORM_INSTANCE_LIST_PAGE_SIZE = 250

/** Lists tenant form instances for a form definition and returns the normalized row matching formInstanceId. */
export async function getFormInstanceByDefinitionAndId(
    forms: Pick<FormsApiLike, 'searchFormInstancesByTenantV1'>,
    formDefinitionId: string,
    formInstanceId: string
): Promise<NormalizedFormInstance> {
    const escapedDefinitionId = escapeODataString(formDefinitionId)
    const filters = `formDefinitionId eq "${escapedDefinitionId}"`
    let offset = 0

    while (true) {
        const response = await callFormsApi('Form instance list', () =>
            forms.searchFormInstancesByTenantV1({
                offset,
                limit: FORM_INSTANCE_LIST_PAGE_SIZE,
                filters,
            })
        )
        const page = Array.isArray(response.data) ? response.data : []

        for (const row of page) {
            if (row?.id === formInstanceId) {
                return normalizeFormInstance({
                    id: row.id,
                    state: row.state,
                    formInput: row.formInput,
                    formData: row.formData,
                    recipients: row.recipients,
                    formInstanceInputs: (row as Record<string, unknown>).formInstanceInputs,
                })
            }
        }

        if (page.length < FORM_INSTANCE_LIST_PAGE_SIZE) {
            break
        }

        offset += page.length
    }

    throw new ConnectorError(`Form instance "${formInstanceId}" not found`)
}
