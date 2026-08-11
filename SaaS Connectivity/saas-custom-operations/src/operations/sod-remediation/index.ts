import { customOperation, OperationSignature } from '../../framework'
import { listAssignedEntitlements, listAssignedEntitlementsOffline } from '../../isc/identity-history'
import {
    fetchKeepRecommendations,
    fetchKeepRecommendationsOffline,
    type KeepRecommendationRequest,
} from '../../isc/recommendations'
import { resolveTokenIdentity } from '../../isc/token-identity'
import { getViolationV1 } from '../../isc/violations'
import { listControlsV1 } from '../../isc/controls'
import {
    fetchIdentityAccessItemsFromSdk,
    fetchIdentityAccessItemsOffline,
} from '../../isc/identity-access'
import { resolveIdentityEmail } from '../../isc/public-identities'
import { resolveIdentityEmailOffline } from '../../isc/public-identities/offline-data'
import {
    computeRecommendedSideToCorrect,
    createPrivilegedEntitlementMap,
    enrichResolvedAccessSides,
} from './access-path-enrichment'
import { AccessPathLine } from './access-path-resolver'
import {
    assembleFormInput,
    buildSituationHeader,
    buildSituationSummary,
    resolveViolationAccessPaths,
} from './context'
import { createSodRemediationInstance, ensureSodFormDefinition } from './form-service'
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
import { OFFLINE_VIOLATION } from './offline-data'

export interface SodRemediationOperation extends OperationSignature {
    command: 'custom:sod-remediation'
    input: {
        violationId: string
        formName: string
        owner?: string
    }
    output: {
        'sod-remediation:form-url': string
        'sod-remediation:situation-summary': string
        'sod-remediation:situation-header': string
        'sod-remediation:owner-email': string
    }
}

function collectKeepRecommendationRequests(
    identityId: string,
    paths: AccessPathLine[]
): KeepRecommendationRequest[] {
    const seen = new Set<string>()

    return paths.flatMap((line) => {
        const key = `${line.type}:${line.id}`
        if (seen.has(key)) {
            return []
        }
        seen.add(key)
        return [{ identityId, itemId: line.id, itemType: line.type }]
    })
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

        let { groupA, groupB } = resolveViolationAccessPaths({ violation, identityAccess })
        let recommendedSideToCorrect = null

        try {
            const recommendationRequests = [
                ...collectKeepRecommendationRequests(violation.identity.id, groupA.accessPaths),
                ...collectKeepRecommendationRequests(violation.identity.id, groupB.accessPaths),
            ]

            const keepRecommendations = offline
                ? fetchKeepRecommendationsOffline(recommendationRequests)
                : await fetchKeepRecommendations(clientConfig, recommendationRequests)

            const assignedEntitlements = offline
                ? listAssignedEntitlementsOffline(violation.identity.id)
                : await listAssignedEntitlements(ctx.sdk.identityHistory, violation.identity.id)

            const privilegedEntitlements = createPrivilegedEntitlementMap(assignedEntitlements)
                ; ({ groupA, groupB } = enrichResolvedAccessSides(
                    groupA,
                    groupB,
                    keepRecommendations,
                    privilegedEntitlements
                ))
            recommendedSideToCorrect = computeRecommendedSideToCorrect(groupA, groupB)
        } catch {
            // Advisory metadata only — launch proceeds without keep or privileged annotations.
        }

        logSodRemediationAccessPaths(ctx.requestId, groupA, groupB)

        const summaryInput = {
            violation,
            groupA,
            groupB,
            controls,
            recommendedSideToCorrect,
        }
        const formInput = assembleFormInput(summaryInput)
        logSodRemediationFormInput(ctx.requestId, formInput)

        const recipientId = input.owner ?? violation.owner.id
        logSodRemediationRecipient(ctx.requestId, recipientId, input.owner ? 'owner-override' : 'violation-owner')

        const ownerEmail = offline
            ? resolveIdentityEmailOffline(recipientId)
            : await resolveIdentityEmail(clientConfig, recipientId)

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

        const situationHeader = buildSituationHeader(summaryInput)
        const situationSummary = buildSituationSummary(summaryInput, { formUrl })

        logSodRemediationOutput(ctx.requestId, {
            formUrl,
            situationHeader,
            situationSummary,
            ownerEmail,
        })
        await ctx.persist(ctx.requestId, {
            'sod-remediation:form-url': formUrl,
            'sod-remediation:situation-header': situationHeader,
            'sod-remediation:situation-summary': situationSummary,
            'sod-remediation:owner-email': ownerEmail,
        })

        logSodRemediationComplete(ctx.requestId)
        ctx.res.send({ status: 'success' })
    }
)
