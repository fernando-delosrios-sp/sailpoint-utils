import { customOperation, OperationSignature, resolveTokenIdentity } from '../framework'
import { getViolationV1, listControlsV1, ViolationV1 } from '../isc/experimental-client'
import {
    fetchIdentityAccessItemsFromSdk,
    fetchIdentityAccessItemsOffline,
} from '../isc/identity-access-client'
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
} from '../isc/sod-remediation-logging'
import {
    assembleFormInput,
    buildSituationSummary,
    resolveViolationAccessPaths,
} from '../isc/sod-remediation-context'
import { createRemediationInstance, ensureFormDefinition } from '../isc/sod-form-service'

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

/** Canned violation used for offline test-mode runs without ISC credentials. */
const OFFLINE_VIOLATION: ViolationV1 = {
    id: 'offline-violation',
    owner: { id: 'offline-owner', name: 'Offline Owner' },
    identity: { id: 'offline-identity', name: 'Offline User' },
    policy: { id: 'offline-policy', name: 'Offline SOD Policy' },
    leftSide: { entitlements: [{ id: 'offline-ent-a', name: 'Offline Entitlement A' }] },
    rightSide: { entitlements: [{ id: 'offline-ent-b', name: 'Offline Entitlement B' }] },
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
        const formDefinitionId = await ensureFormDefinition(ctx.sdk.forms, input.formName, definitionOwnerId)
        logSodRemediationFormDefinition(
            ctx.requestId,
            input.formName,
            formDefinitionId,
            definitionOwnerId,
            definitionOwnerSource
        )

        const formUrl = await createRemediationInstance({
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
