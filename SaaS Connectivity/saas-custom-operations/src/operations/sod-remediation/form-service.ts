import {
    buildCreateFormDefinitionPayload,
    FormsApiLike,
    loadFormSeed,
    pickDeclaredFormInputValues,
} from '../../isc/forms'
import { launchForm, FormLaunchNotification } from '../../lib/form-launch'
import { FormNotification } from '../../lib/form-notification'
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
    groupColumnsHtmlPlain: string
    groupColumnsHtmlWhenGroupARemoved: string
    groupColumnsHtmlWhenGroupBRemoved: string
    hasControls: boolean
    violationId: string
    targetIdentityId: string
    groupAAccessSearch: string
    groupBAccessSearch: string
    controlOptions: FormInputSelectOption[]
}

export interface LaunchSodRemediationFormParams {
    forms: FormsApiLike
    formName: string
    definitionOwnerId: string
    recipientId: string
    createdBySourceId: string
    formInput: SodFormInputValues
    notification: FormLaunchNotification
}

const sodRemediationSeed = loadFormSeed(sodViolationRemediationSeed)

/** Supplies the operation seed and formInput serialization to the shared form launch facade. */
export async function launchSodRemediationForm(params: LaunchSodRemediationFormParams): Promise<FormNotification> {
    const { forms, formName, definitionOwnerId, recipientId, createdBySourceId, formInput, notification } = params
    const template = buildCreateFormDefinitionPayload(
        formName,
        definitionOwnerId,
        sodRemediationSeed,
        sodRemediationSeed.description
    )
    const instanceFormInput = pickDeclaredFormInputValues(sodRemediationSeed, {
        ...formInput,
        hasControls: String(formInput.hasControls),
    })

    return launchForm({
        forms,
        definition: { formName, ownerId: definitionOwnerId, template },
        recipientId,
        createdBySourceId,
        formInput: instanceFormInput,
        notification,
    })
}
