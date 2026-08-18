import {
    buildCreateFormDefinitionPayload,
    createStandaloneFormInstance,
    ensureFormDefinitionByName,
    FormsApiLike,
    loadFormSeed,
    pickDeclaredFormInputValues,
} from '../../isc/forms'
import { logIscDebug } from '../../isc/debug/log-isc-request'
import accessModelSodRemediationSeedJson from './seed/access-model-sod-remediation.seed.json'

export interface AccessModelSodFormInputValues {
    parentRequestId: string
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
