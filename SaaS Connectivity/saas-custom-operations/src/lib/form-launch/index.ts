import {
    createStandaloneFormInstance,
    ensureFormDefinitionByName,
    FormsApiLike,
} from '../../isc/forms'
import { CreateFormDefinitionPayload } from '../../isc/forms/seed-loader'
import { FormNotification } from '../form-notification'

export type FormLaunchContext = {
    formUrl: string
}

export type FormLaunchValue<T> = T | ((context: FormLaunchContext) => T)

export type FormLaunchNotification = {
    emailHeader: FormLaunchValue<string>
    emailBody: FormLaunchValue<string>
    emailRecipients: FormLaunchValue<string[]>
}

export type FormLaunchDefinition =
    | {
          formDefinitionId: string
      }
    | {
          formName: string
          ownerId: string
          template: CreateFormDefinitionPayload
      }

export type LaunchFormParams = {
    forms: FormsApiLike
    definition: FormLaunchDefinition
    recipientId: string
    createdBySourceId: string
    formInput: Record<string, unknown>
    expire?: string
    notification: FormLaunchNotification
}

function resolveValue<T>(value: FormLaunchValue<T>, context: FormLaunchContext): T {
    return typeof value === 'function' ? (value as (context: FormLaunchContext) => T)(context) : value
}

async function resolveDefinitionId(forms: FormsApiLike, definition: FormLaunchDefinition): Promise<string> {
    if ('formDefinitionId' in definition) {
        return definition.formDefinitionId
    }

    return ensureFormDefinitionByName(forms, {
        name: definition.formName,
        ownerId: definition.ownerId,
        template: definition.template,
    })
}

/**
 * Ensures a form definition, creates its standalone instance, and pairs the URL
 * with workflow notification fields. Persistence and recipient policy stay with callers.
 */
export async function launchForm(params: LaunchFormParams): Promise<FormNotification> {
    const formDefinitionId = await resolveDefinitionId(params.forms, params.definition)
    const formUrl = await createStandaloneFormInstance({
        forms: params.forms,
        formDefinitionId,
        recipientId: params.recipientId,
        createdBySourceId: params.createdBySourceId,
        formInput: params.formInput,
        expire: params.expire,
    })
    const context = { formUrl }

    return {
        formUrl,
        emailHeader: resolveValue(params.notification.emailHeader, context),
        emailBody: resolveValue(params.notification.emailBody, context),
        emailRecipients: resolveValue(params.notification.emailRecipients, context),
    }
}
