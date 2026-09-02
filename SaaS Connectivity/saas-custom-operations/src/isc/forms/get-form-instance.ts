import { ConnectorError } from '@sailpoint/connector-sdk'
import { callFormsApi } from './error-formatting'
import { FormsApiLike } from './ensure-definition'

export interface NormalizedFormInstance {
    id: string
    state: string
    formInput: Record<string, string>
    formData: Record<string, string>
    submitterId?: string
}

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

function unwrapFormFieldValue(value: unknown): unknown {
    if (!isRecord(value) || typeof value.id !== 'string' || !('value' in value)) {
        return value
    }
    return value.value
}

function normalizeStringMap(raw: unknown): Record<string, string> {
    if (!isRecord(raw)) {
        return {}
    }

    const result: Record<string, string> = {}
    for (const [key, value] of Object.entries(raw)) {
        if (value === undefined || value === null) {
            continue
        }
        const normalized = unwrapFormFieldValue(value)
        if (typeof normalized === 'string') {
            result[key] = normalized
        } else if (typeof normalized === 'number' || typeof normalized === 'boolean') {
            result[key] = String(normalized)
        } else if (normalized !== undefined && normalized !== null) {
            result[key] = JSON.stringify(normalized)
        }
    }
    return result
}

function normalizeFormInstanceInputs(raw: unknown): Record<string, string> {
    if (!Array.isArray(raw)) {
        return {}
    }

    const result: Record<string, string> = {}
    for (const entry of raw) {
        if (!isRecord(entry) || typeof entry.id !== 'string') {
            continue
        }
        const value = entry.value
        if (value === undefined || value === null) {
            continue
        }
        result[entry.id] = typeof value === 'string' ? value : JSON.stringify(value)
    }
    return result
}

/** Normalizes a Custom Forms instance payload into string maps for formInput and formData. */
export function normalizeFormInstance(data: {
    id: string
    state?: string
    formInput?: unknown
    formData?: unknown
    recipients?: Array<{ id?: string }>
    formInstanceInputs?: unknown
}): NormalizedFormInstance {
    const formInputFromInputs = normalizeFormInstanceInputs(data.formInstanceInputs)
    const formInput = {
        ...normalizeStringMap(data.formInput),
        ...formInputFromInputs,
    }

    return {
        id: data.id,
        state: data.state ?? '',
        formInput,
        formData: normalizeStringMap(data.formData),
        submitterId: data.recipients?.[0]?.id,
    }
}

/** Fetches a form instance and returns normalized string maps for formInput and formData. */
export async function getFormInstanceById(
    forms: FormsApiLike,
    formInstanceId: string
): Promise<NormalizedFormInstance> {
    const response = await callFormsApi('Form instance get', () =>
        forms.getFormInstanceByKeyV1({ formInstanceID: formInstanceId })
    )
    const data = response.data
    if (!data?.id) {
        throw new ConnectorError(`Form instance "${formInstanceId}" not found`)
    }

    return normalizeFormInstance({
        id: data.id,
        state: data.state,
        formInput: data.formInput,
        formData: data.formData,
        recipients: data.recipients,
        formInstanceInputs: (data as Record<string, unknown>).formInstanceInputs,
    })
}
