import { ConnectorError } from '@sailpoint/connector-sdk'
import { escapeODataString } from '../accounts'
import { callFormsApi } from './error-formatting'
import { FormsApiLike } from './ensure-definition'
import { normalizeFormInstance, NormalizedFormInstance } from './get-form-instance'

export const FORM_INSTANCE_LIST_PAGE_SIZE = 250

function isHttpStatus(error: unknown, status: number): boolean {
    if (typeof error !== 'object' || error === null) {
        return false
    }

    const candidate = error as { status?: number; response?: { status?: number } }
    if (candidate.status === status || candidate.response?.status === status) {
        return true
    }

    if (error instanceof ConnectorError && error.message.includes(`status ${status}`)) {
        return true
    }

    return false
}

function pickInstanceFromPage(
    page: unknown[],
    formInstanceId: string
): NormalizedFormInstance | undefined {
    for (const row of page) {
        const candidate = row as {
            id?: string
            state?: string
            formInput?: unknown
            formData?: unknown
            recipients?: unknown
            formInstanceInputs?: unknown
        }
        if (candidate?.id === formInstanceId) {
            return normalizeFormInstance({
                id: candidate.id,
                state: candidate.state,
                formInput: candidate.formInput,
                formData: candidate.formData,
                recipients: Array.isArray(candidate.recipients)
                    ? (candidate.recipients as { id?: string }[])
                    : undefined,
                formInstanceInputs: (candidate as Record<string, unknown>).formInstanceInputs,
            })
        }
    }
    return undefined
}

/** Pages tenant form instances for a definition until formInstanceId matches (legacy fallback). */
async function listAndPickFormInstance(
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
        const match = pickInstanceFromPage(page, formInstanceId)
        if (match) {
            return match
        }

        if (page.length < FORM_INSTANCE_LIST_PAGE_SIZE) {
            break
        }

        offset += page.length
    }

    throw new ConnectorError(`Form instance "${formInstanceId}" not found`)
}

/**
 * Loads a tenant form instance by definition id and instance id.
 * Prefers a single filtered search; falls back to paginated list-and-pick when the
 * combined filter is rejected (HTTP 400).
 */
export async function getFormInstanceByDefinitionAndId(
    forms: Pick<FormsApiLike, 'searchFormInstancesByTenantV1'>,
    formDefinitionId: string,
    formInstanceId: string
): Promise<NormalizedFormInstance> {
    const escapedDefinitionId = escapeODataString(formDefinitionId)
    const escapedInstanceId = escapeODataString(formInstanceId)
    const filters = `formDefinitionId eq "${escapedDefinitionId}" and id eq "${escapedInstanceId}"`

    try {
        const response = await callFormsApi('Form instance list', () =>
            forms.searchFormInstancesByTenantV1({
                offset: 0,
                limit: 1,
                filters,
            })
        )
        const page = Array.isArray(response.data) ? response.data : []
        const match = pickInstanceFromPage(page, formInstanceId)
        if (match) {
            return match
        }
        throw new ConnectorError(`Form instance "${formInstanceId}" not found`)
    } catch (error) {
        if (error instanceof ConnectorError && error.message.includes('not found')) {
            throw error
        }
        if (isHttpStatus(error, 400)) {
            return listAndPickFormInstance(forms, formDefinitionId, formInstanceId)
        }
        throw error
    }
}
