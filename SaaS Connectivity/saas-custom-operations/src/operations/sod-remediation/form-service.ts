import {
    buildCreateFormDefinitionPayload,
    createStandaloneFormInstance,
    ensureFormDefinitionByName,
    FormsApiLike,
    loadFormSeed,
    pickDeclaredFormInputValues,
} from '../../isc/forms'
import sodViolationRemediationSeed from './seed/sod-violation-remediation.seed.json'

export interface FormInputSelectOption {
    label: string
    value: string
    sublabel?: string
}

export interface SodFormInputValues {
    targetIdentityName: string
    policyName: string
    situationSummaryHtml: string
    groupAContentsHtml: string
    groupBContentsHtml: string
    hasControls: boolean
    violationId: string
    targetIdentityId: string
    groupAAccessSearch: string
    groupBAccessSearch: string
    controlOptions: FormInputSelectOption[]
}

export interface CreateRemediationInstanceParams {
    forms: FormsApiLike
    formDefinitionId: string
    recipientId: string
    createdBySourceId: string
    formInput: SodFormInputValues
}

const sodRemediationSeed = loadFormSeed(sodViolationRemediationSeed)

/** Ensures the SOD remediation form definition exists, creating from the operation-local seed when absent. */
export async function ensureSodFormDefinition(forms: FormsApiLike, formName: string, ownerId: string): Promise<string> {
    const template = buildCreateFormDefinitionPayload(formName, ownerId, sodRemediationSeed, sodRemediationSeed.description)
    return ensureFormDefinitionByName(forms, { name: formName, ownerId, template })
}

/** Creates a standalone SOD remediation form instance for the recipient. */
export async function createSodRemediationInstance(params: CreateRemediationInstanceParams): Promise<string> {
    const { forms, formDefinitionId, recipientId, createdBySourceId, formInput } = params
    const instanceFormInput = pickDeclaredFormInputValues(sodRemediationSeed, {
        ...formInput,
        hasControls: String(formInput.hasControls),
    })

    return createStandaloneFormInstance({
        forms,
        formDefinitionId,
        recipientId,
        createdBySourceId,
        formInput: instanceFormInput,
    })
}

