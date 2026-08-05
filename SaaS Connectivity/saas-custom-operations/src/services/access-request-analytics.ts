import type { SailPointClients } from '../framework/types'
import { AccessService } from './access.service'
import { RecommendationService } from './recommendation.service'
import { SodService } from './sod.service'
import type { AccessRequestAnalytics, AccessRequestStatusPayload, GetAccessRequestStatus } from './types'

function extractIscRiskName(accessModelMetadata: Record<string, unknown> | null): string {
    const attributes = accessModelMetadata?.attributes as
        | Array<{ key?: string; values?: Array<{ name?: string }> }>
        | undefined
    const iscRisk = attributes?.find((attr) => attr.key === 'iscRisk')?.values?.[0]?.name
    return iscRisk ?? 'N/A'
}

function formatViolatedPolicyNames(
    localViolations: Array<{ policyName: string }>,
    status: GetAccessRequestStatus
): string {
    const violatedPolicyNamesSet = new Set<string>()
    localViolations.forEach((violation) => violatedPolicyNamesSet.add(violation.policyName))

    const contextViolations = status.sodViolationContext?.violationCheckResult?.violatedPolicies
    if (contextViolations && Array.isArray(contextViolations)) {
        contextViolations.forEach((policy) => {
            if (policy.name) {
                violatedPolicyNamesSet.add(policy.name)
            }
        })
    }

    return Array.from(violatedPolicyNamesSet).join(', ') || 'N/A'
}

function formatRecommendations(
    recommendations: { response?: Array<{ recommendation?: string; interpretations?: string[] }> } | null
): { recommendationsDecision: string; recommendationsInterpretations: string } {
    const recResponses = recommendations?.response ?? []
    if (recResponses.length === 0 || !recResponses[0]) {
        return {
            recommendationsDecision: 'N/A',
            recommendationsInterpretations: 'N/A',
        }
    }

    const firstRecommendation = recResponses[0]
    return {
        recommendationsDecision: firstRecommendation.recommendation ?? 'N/A',
        recommendationsInterpretations: firstRecommendation.interpretations?.length
            ? firstRecommendation.interpretations.join(' | ')
            : 'N/A',
    }
}

function formatSodPrediction(predictedViolations: unknown): string {
    if (!predictedViolations || !Array.isArray(predictedViolations) || predictedViolations.length === 0) {
        return 'N/A'
    }

    const predictedPolicyNames = predictedViolations
        .map((violation) => (violation as { policy?: { name?: string } })?.policy?.name)
        .filter((name): name is string => !!name)

    return predictedPolicyNames.length > 0 ? predictedPolicyNames.join(', ') : 'N/A'
}

function formatXdrScore(xdrData: AccessRequestStatusPayload['getXdrData']): string {
    if (xdrData?.score === undefined || xdrData.score === null) {
        return 'N/A'
    }
    return `${(xdrData.score * 100).toFixed(2)}%`
}

export async function computeAccessRequestAnalytics(
    sdk: SailPointClients,
    accessRequestId: string
): Promise<AccessRequestAnalytics | null> {
    const accessService = new AccessService(sdk)
    const sodService = new SodService(sdk)
    const recommendationService = new RecommendationService(sdk)

    const accessRequestStatus = await accessService.fetchAccessRequestById(accessRequestId)
    if (!accessRequestStatus?.requestedFor?.id || !accessRequestStatus.type || !accessRequestStatus.id) {
        return null
    }

    const identityId = accessRequestStatus.requestedFor.id
    const requestedItemId = accessRequestStatus.id
    const requestedType = accessRequestStatus.type

    const xdrData = await accessService.fetchOutlierByIdentityId(identityId)
    const payload = accessService.buildPayload(accessRequestStatus, xdrData)

    const [requestedEntitlements, pendingEntitlements, accessModelMetadata] = await Promise.all([
        accessService.getUnderlyingEntitlements(payload),
        accessService.getPendingEntitlements(identityId, accessRequestStatus.accessRequestId ?? accessRequestId),
        accessService.getRequestedItemMetadata(requestedItemId, requestedType),
    ])

    const allEntitlementsMap = new Map<string, (typeof requestedEntitlements)[number]>()
    pendingEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
    requestedEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
    const combinedEntitlements = Array.from(allEntitlementsMap.values())

    const accessRefsPayload = requestedEntitlements.map((ent) => ({ id: ent.id, type: 'ENTITLEMENT' as const }))
    const [policies, predictedViolations, recommendations] = await Promise.all([
        sodService.fetchSodPolicies(),
        accessRefsPayload.length > 0
            ? sodService.predictSodViolations(identityId, accessRefsPayload)
            : Promise.resolve(null),
        recommendationService.fetchRecommendations(identityId, requestedItemId, requestedType),
    ])

    const localViolations = sodService.checkPoliciesAgainstEntitlements(combinedEntitlements, policies)
    const recommendationStrings = formatRecommendations(recommendations)

    return {
        iscRiskName: extractIscRiskName(accessModelMetadata),
        xdrScore: formatXdrScore(xdrData),
        sodPrediction: formatSodPrediction(predictedViolations),
        violatedPolicyNames: formatViolatedPolicyNames(localViolations, accessRequestStatus),
        recommendationsDecision: recommendationStrings.recommendationsDecision,
        recommendationsInterpretations: recommendationStrings.recommendationsInterpretations,
        accessRequestStatus,
        xdrData,
    }
}

export async function fetchIdentityDisplayContext(
    sdk: SailPointClients,
    identityId: string
): Promise<{ displayName: string; managerRefName: string }> {
    try {
        const response = await sdk.identities.getIdentityV1({ id: identityId })
        const identity = response.data
        const attributes = identity?.attributes as Record<string, string> | undefined
        return {
            displayName: attributes?.displayName ?? identity?.name ?? 'User',
            managerRefName: identity?.managerRef?.name ?? 'Approver',
        }
    } catch (error) {
        console.error(`[AccessRequestAnalytics] Error fetching identity ${identityId}:`, error)
        return {
            displayName: 'User',
            managerRefName: 'Approver',
        }
    }
}
