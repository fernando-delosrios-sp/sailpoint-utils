import { ConnectorError } from '@sailpoint/connector-sdk'
import { NormalizedFormInstance } from '../../isc/forms/get-form-instance'

export type RemediationSide = 'groupA' | 'groupB'
export type AccessItemType = 'ROLE' | 'ACCESS_PROFILE'

export interface ParsedFormInstance {
    formInstanceId: string
    accessItemId: string
    accessItemType: AccessItemType
    policyId: string
    policyName: string
    remediationSide: RemediationSide
    groupAIds: string[]
    groupBIds: string[]
    comments?: string
    submitterId?: string
}

function parseJsonArray(raw: string, fieldName: string, formInstanceId: string): string[] {
    try {
        const parsed = JSON.parse(raw) as unknown
        if (!Array.isArray(parsed) || !parsed.every((value) => typeof value === 'string')) {
            throw new Error('not a string array')
        }
        return parsed
    } catch {
        throw new ConnectorError(
            `Form instance "${formInstanceId}" has invalid JSON in formInput.${fieldName}`
        )
    }
}

/** Validates and parses a completed access-model SoD remediation form instance. */
export function parseFormInstance(instance: NormalizedFormInstance): ParsedFormInstance {
    if (instance.state !== 'COMPLETED') {
        throw new ConnectorError(
            `Form instance "${instance.id}" must be COMPLETED (current: ${instance.state || 'unknown'})`
        )
    }

    const remediationSide = instance.formData.remediationSide
    if (remediationSide !== 'groupA' && remediationSide !== 'groupB') {
        throw new ConnectorError(
            `Form instance "${instance.id}" missing valid formData.remediationSide`
        )
    }

    const requiredInputKeys = [
        'accessItemId',
        'accessItemType',
        'policyId',
        'policyName',
        'groupAIds',
        'groupBIds',
    ] as const
    for (const key of requiredInputKeys) {
        if (!instance.formInput[key]) {
            throw new ConnectorError(`Form instance "${instance.id}" missing formInput.${key}`)
        }
    }

    const accessItemType = instance.formInput.accessItemType
    if (accessItemType !== 'ROLE' && accessItemType !== 'ACCESS_PROFILE') {
        throw new ConnectorError(
            `Form instance "${instance.id}" has invalid formInput.accessItemType: ${accessItemType}`
        )
    }

    return {
        formInstanceId: instance.id,
        accessItemId: instance.formInput.accessItemId,
        accessItemType,
        policyId: instance.formInput.policyId,
        policyName: instance.formInput.policyName,
        remediationSide,
        groupAIds: parseJsonArray(instance.formInput.groupAIds, 'groupAIds', instance.id),
        groupBIds: parseJsonArray(instance.formInput.groupBIds, 'groupBIds', instance.id),
        comments: instance.formData.comments,
        submitterId: instance.submitterId,
    }
}
