import { resolve } from 'path'
import { ensureFormDefinitionByName, FormsApiLike } from '../../isc/forms/ensure-definition'
import { createStandaloneFormInstance } from '../../isc/forms/create-instance'
import { buildCreateFormDefinitionPayload, loadFormSeed } from '../../isc/forms/seed-loader'

const SOD_SEED_PATH = resolve(__dirname, 'seed/sod-violation-remediation.seed.json')

export interface FormInputSelectOption {
    label: string
    value: string
    sublabel?: string
}

export interface SodFormInputValues {
    targetIdentityName: string
    policyName: string
    situationSummaryHtml: string
    groupAContents: string
    groupBContents: string
    groupAWarning: string
    groupBWarning: string
    hasControls: boolean
    violationId: string
    targetIdentityId: string
    groupARevokePayload: string
    groupBRevokePayload: string
    controlOptions: FormInputSelectOption[]
}

export interface CreateRemediationInstanceParams {
    forms: FormsApiLike
    formDefinitionId: string
    recipientId: string
    createdBySourceId: string
    formInput: SodFormInputValues
}

/** Ensures the SOD remediation form definition exists, creating from the operation-local seed when absent. */
export async function ensureSodFormDefinition(forms: FormsApiLike, formName: string, ownerId: string): Promise<string> {
    const seed = loadFormSeed(SOD_SEED_PATH)
    const template = buildCreateFormDefinitionPayload(formName, ownerId, seed, seed.description)
    return ensureFormDefinitionByName(forms, { name: formName, ownerId, template })
}

/** Creates a standalone SOD remediation form instance for the recipient. */
export async function createSodRemediationInstance(params: CreateRemediationInstanceParams): Promise<string> {
    const { forms, formDefinitionId, recipientId, createdBySourceId, formInput } = params
    return createStandaloneFormInstance({
        forms,
        formDefinitionId,
        recipientId,
        createdBySourceId,
        formInput: {
            ...formInput,
            hasControls: String(formInput.hasControls),
        },
    })
}
