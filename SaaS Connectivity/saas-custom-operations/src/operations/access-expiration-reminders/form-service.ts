import {
    buildCreateFormDefinitionPayload,
    createStandaloneFormInstance,
    ensureFormDefinitionByName,
    FormsApiLike,
    loadFormSeed,
    pickDeclaredFormInputValues,
} from '../../isc/forms'
import { logIscDebug } from '../../isc/debug/log-isc-request'
import accessExpirationRemindersSeedJson from './seed/access-expiration-reminders.seed.json'

export interface AccessExpirationRemindersFormInputValues {
    responseAccountId: string
    identityId: string
    accessProfileId: string
    identityDisplayName: string
    accessProfileName: string
    removeDate: string
    daysRemaining: string
    situationSummaryHtml: string
}

export interface CreateAccessExpirationRemindersInstanceParams {
    forms: FormsApiLike
    formDefinitionId: string
    recipientId: string
    createdBySourceId: string
    formInput: AccessExpirationRemindersFormInputValues
    expire: string
}

const accessExpirationRemindersSeed = loadFormSeed(accessExpirationRemindersSeedJson)

/** Ensures the access expiration reminders form definition exists for the tenant. */
export async function ensureAccessExpirationRemindersFormDefinition(
    forms: FormsApiLike,
    formName: string,
    ownerId: string
): Promise<string> {
    const template = buildCreateFormDefinitionPayload(
        formName,
        ownerId,
        accessExpirationRemindersSeed,
        accessExpirationRemindersSeed.description
    )
    return ensureFormDefinitionByName(forms, { name: formName, ownerId, template })
}

/** Creates a standalone manager reminder form instance that expires at the assignment removeDate. */
export async function createAccessExpirationRemindersInstance(
    params: CreateAccessExpirationRemindersInstanceParams
): Promise<string> {
    const { forms, formDefinitionId, recipientId, createdBySourceId, formInput, expire } = params
    const instanceFormInput = pickDeclaredFormInputValues(
        accessExpirationRemindersSeed,
        formInput as unknown as Record<string, unknown>
    )
    logIscDebug('createAccessExpirationRemindersInstance formInput', {
        keys: Object.keys(instanceFormInput),
        expire,
    })

    return createStandaloneFormInstance({
        forms,
        formDefinitionId,
        recipientId,
        createdBySourceId,
        formInput: instanceFormInput,
        expire,
    })
}
