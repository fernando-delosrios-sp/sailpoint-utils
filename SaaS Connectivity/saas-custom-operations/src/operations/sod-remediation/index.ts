import { customOperation, OperationSignature } from '../../framework'
import { resolveTokenIdentity } from '../../isc/token-identity'
import { getViolationV1 } from '../../isc/violations'
import { listControlsV1 } from '../../isc/controls'
import {
    fetchIdentityAccessItemsFromSdk,
    fetchIdentityAccessItemsOffline,
} from '../../isc/identity-access'
import {
    assembleFormInput,
    buildSituationSummary,
    resolveViolationAccessPaths,
} from './context'
import { createSodRemediationInstance, ensureSodFormDefinition } from './form-service'
import { OFFLINE_VIOLATION } from './offline-data'
import {
    logSodRemediationAccessPaths,
    logSodRemediationComplete,
    logSodRemediationControls,
    logSodRemediationFormDefinition,
    logSodRemediationFormInput,
    logSodRemediationIdentityAccess,
    logSodRemediationInput,
    logSodRemediationOutput,
    logSodRemediationRecipient,
    logSodRemediationViolation,
} from './logging'

export interface SodRemediationOperation extends OperationSignature {
    command: 'custom:sod-remediation'
    input: {
        violationId: string
        formName: string
        owner?: string
    }
    output: {
        formUrl: string
        situationSummary: string
    }
}

/** Launch-only SOD remediation operation — prepares form instance and returns URL + summary. */
export const sodRemediationOperation = customOperation<SodRemediationOperation>(
    async (ctx, input) => {
        const offline = !ctx.apiUrl && !ctx.token
        const clientConfig = { apiUrl: ctx.apiUrl, token: ctx.token }

        logSodRemediationInput(ctx.requestId, input, offline)

        const violation = offline
            ? { ...OFFLINE_VIOLATION, id: input.violationId }
            : await getViolationV1(clientConfig, input.violationId)
        logSodRemediationViolation(ctx.requestId, violation, offline ? 'offline' : 'isc')

        const controls = offline ? [] : await listControlsV1(clientConfig)
        logSodRemediationControls(ctx.requestId, controls)

        const identityAccess = offline
            ? await fetchIdentityAccessItemsOffline(violation.identity.id)
            : await fetchIdentityAccessItemsFromSdk(ctx.sdk, violation.identity.id)
        logSodRemediationIdentityAccess(ctx.requestId, identityAccess)

        const { groupA, groupB } = resolveViolationAccessPaths({ violation, identityAccess })
        logSodRemediationAccessPaths(ctx.requestId, groupA, groupB)

        const situationSummary = buildSituationSummary({ violation, groupA, groupB, controls })
        const formInput = assembleFormInput({ violation, groupA, groupB, controls })
        logSodRemediationFormInput(ctx.requestId, formInput)

        const recipientId = input.owner ?? violation.owner.id
        logSodRemediationRecipient(ctx.requestId, recipientId, input.owner ? 'owner-override' : 'violation-owner')

        const definitionOwnerId = offline ? OFFLINE_VIOLATION.owner.id : resolveTokenIdentity(ctx.token)
        const definitionOwnerSource = offline ? 'offline-fallback' : 'token-identity'
        const formDefinitionId = await ensureSodFormDefinition(ctx.sdk.forms, input.formName, definitionOwnerId)
        logSodRemediationFormDefinition(
            ctx.requestId,
            input.formName,
            formDefinitionId,
            definitionOwnerId,
            definitionOwnerSource
        )

        const formUrl = await createSodRemediationInstance({
            forms: ctx.sdk.forms,
            formDefinitionId,
            recipientId,
            createdBySourceId: ctx.sourceId,
            formInput,
        })

        logSodRemediationOutput(ctx.requestId, formUrl, situationSummary)
        await ctx.persist(ctx.requestId, { formUrl, situationSummary })

        logSodRemediationComplete(ctx.requestId)
        ctx.res.send({ status: 'success' })
    }
)

