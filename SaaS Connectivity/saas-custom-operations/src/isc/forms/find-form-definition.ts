import { ConnectorError } from '@sailpoint/connector-sdk'
import { escapeODataString } from '../accounts'
import { callFormsApi } from './error-formatting'
import { FormsApiLike } from './ensure-definition'

/** Finds an existing tenant form definition by exact name without creating or patching it. */
export async function findFormDefinitionIdByName(
    forms: Pick<FormsApiLike, 'searchFormDefinitionsByTenantV1'>,
    formName: string
): Promise<string> {
    const escapedName = escapeODataString(formName)
    const response = await callFormsApi('Form definition search', () =>
        forms.searchFormDefinitionsByTenantV1({
            filters: `name eq "${escapedName}"`,
        })
    )
    const definitionId = response.data?.results?.[0]?.id

    if (!definitionId) {
        throw new ConnectorError(`Form definition not found for formName "${formName}"`)
    }

    return definitionId
}
