import {
    buildCreateFormDefinitionPayload,
    createStandaloneFormInstance,
    ensureFormDefinitionByName,
    FormsApiLike,
    loadFormSeed,
    pickDeclaredFormInputValues,
} from '../../isc/forms'
import { logIscDebug, logIscRequestFailure } from '../../isc/debug/log-isc-request'
import accessModelSodRemediationSeedJson from './seed/access-model-sod-remediation.seed.json'

export interface AccessModelSodFormInputValues {
    accessItemId: string
    accessItemType: string
    accessItemTypeTagHtml: string
    accessItemName: string
    policyId: string
    policyName: string
    groupAIds: string[]
    groupBIds: string[]
    groupColumnsHtmlPlain: string
    groupColumnsHtmlWhenGroupARemoved: string
    groupColumnsHtmlWhenGroupBRemoved: string
}

export interface CreateAccessModelSodInstanceParams {
    forms: FormsApiLike
    formDefinitionId: string
    recipientId: string
    createdBySourceId: string
    formInput: AccessModelSodFormInputValues
}

const accessModelSodRemediationSeed = loadFormSeed(accessModelSodRemediationSeedJson)

/** Ensures the access model SoD remediation form definition exists for the tenant. */
export async function ensureAccessModelSodFormDefinition(
    forms: FormsApiLike,
    formName: string,
    ownerId: string
): Promise<string> {
    const template = buildCreateFormDefinitionPayload(
        formName,
        ownerId,
        accessModelSodRemediationSeed,
        accessModelSodRemediationSeed.description
    )
    return ensureFormDefinitionByName(forms, { name: formName, ownerId, template })
}

/** Returns true when an ASSIGNED instance already exists for the same access item and policy. */
export async function hasAssignedRemediationInstance(
    forms: FormsApiLike,
    formDefinitionId: string,
    accessItemId: string,
    policyId: string
): Promise<boolean> {
    const filters = `formDefinitionId eq "${formDefinitionId}"`
    logIscDebug('hasAssignedRemediationInstance searchFormInstancesByTenantV1 request', {
        filters,
        accessItemId,
        policyId,
    })

    try {
        const response = await forms.searchFormInstancesByTenantV1({
            filters,
            limit: 250,
        })

        const instances = response.data ?? []
        const assigned = instances.filter((instance) => instance.state === 'ASSIGNED')
        logIscDebug('hasAssignedRemediationInstance response', {
            totalInstances: instances.length,
            assignedInstances: assigned.length,
        })

        return assigned.some((instance) => {
            const input = instance.formInput as Record<string, unknown> | undefined
            return input?.accessItemId === accessItemId && input?.policyId === policyId
        })
    } catch (error) {
        logIscRequestFailure('hasAssignedRemediationInstance searchFormInstancesByTenantV1', error)
        throw error
    }
}

/** Serializes entitlement id lists to JSON strings for ISC STRING formInput fields. */
export function serializeAccessModelSodFormInputForCreate(formInput: AccessModelSodFormInputValues): Record<string, unknown> {
    return {
        ...formInput,
        groupAIds: JSON.stringify(formInput.groupAIds),
        groupBIds: JSON.stringify(formInput.groupBIds),
    }
}

/** Creates a standalone access model SoD remediation form instance for the policy owner. */
export async function createAccessModelSodRemediationInstance(params: CreateAccessModelSodInstanceParams): Promise<string> {
    const { forms, formDefinitionId, recipientId, createdBySourceId, formInput } = params
    const instanceFormInput = pickDeclaredFormInputValues(
        accessModelSodRemediationSeed,
        serializeAccessModelSodFormInputForCreate(formInput)
    )
    logIscDebug('createAccessModelSodRemediationInstance formInput', {
        keys: Object.keys(instanceFormInput),
        groupAIds: instanceFormInput.groupAIds,
        groupBIds: instanceFormInput.groupBIds,
    })

    return createStandaloneFormInstance({
        forms,
        formDefinitionId,
        recipientId,
        createdBySourceId,
        formInput: instanceFormInput,
    })
}

export function buildAccessModelSodFormInput(values: AccessModelSodFormInputValues): AccessModelSodFormInputValues {
    return values
}
