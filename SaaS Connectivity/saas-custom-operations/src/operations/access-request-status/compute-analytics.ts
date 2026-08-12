import type { SailPointClients } from '../../framework/types'
import {
    getPendingEntitlements,
    getUnderlyingEntitlements,
} from '../../isc/access-requests/entitlement-aggregation'
import { fetchAccessRequestById } from '../../isc/access-requests/fetch-access-request-by-id'
import type { GetAccessRequestStatus } from '../../isc/access-requests/entitlement-types'
import { getRequestedItemMetadata } from '../../isc/access-requests/requested-item'
import { fetchIdentityOutlier, formatOutlierScore } from '../../isc/outliers/fetch-identity-outlier'
import {
    fetchItemRecommendations,
    formatRecommendations,
} from '../../isc/recommendations/fetch-item-recommendations'
import { checkPoliciesAgainstEntitlements } from '../../isc/sod-policies/check-policies-against-entitlements'
import { listEnforcedSodPolicies } from '../../isc/sod-policies/list-enforced-policies'
import {
    parseViolatedPolicyNames,
    predictSodViolationsForIdentity,
} from '../../isc/sod-prediction/predict-violations'

export type EmailRoute = 'manager' | 'manager-owner' | 'manager-owner-bcc' | 'failure'

export type OutputProfile = 'approval-email' | 'ets-comment'

export interface AccessRequestAnalytics {
    iscRiskName: string
    xdrScore: string
    sodPrediction: string
    violatedPolicyNames: string
    recommendationsDecision: string
    recommendationsInterpretations: string
    accessRequestStatus: GetAccessRequestStatus
    xdrData: { score?: number; [key: string]: unknown } | null
}

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

function formatSodPredictionFromPredictResponse(policyNames: string[]): string {
    return policyNames.length > 0 ? policyNames.join(', ') : 'N/A'
}

/** Computes workflow-safe analytics for an access request approval workflow. */
export async function computeAccessRequestAnalytics(
    sdk: SailPointClients,
    accessRequestId: string
): Promise<AccessRequestAnalytics | null> {
    const accessRequestStatus = await fetchAccessRequestById(sdk.accessRequests, accessRequestId)
    if (!accessRequestStatus?.requestedFor?.id || !accessRequestStatus.type || !accessRequestStatus.id) {
        return null
    }

    const identityId = accessRequestStatus.requestedFor.id
    const requestedItemId = accessRequestStatus.id
    const requestedType = accessRequestStatus.type

    const xdrData = await fetchIdentityOutlier(sdk.iaiOutliers, identityId)

    const [requestedEntitlements, pendingEntitlements, accessModelMetadata] = await Promise.all([
        getUnderlyingEntitlements(sdk, accessRequestStatus),
        getPendingEntitlements(sdk, identityId, accessRequestStatus.accessRequestId ?? accessRequestId),
        getRequestedItemMetadata(sdk, requestedItemId, requestedType),
    ])

    const allEntitlementsMap = new Map<string, (typeof requestedEntitlements)[number]>()
    pendingEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
    requestedEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
    const combinedEntitlements = Array.from(allEntitlementsMap.values())

    const entitlementIds = requestedEntitlements.map((ent) => ent.id)
    const [policies, predictedViolations, recommendations] = await Promise.all([
        listEnforcedSodPolicies(sdk.sodPolicies),
        entitlementIds.length > 0
            ? predictSodViolationsForIdentity(sdk.sodViolations, identityId, entitlementIds)
            : Promise.resolve({ violationContexts: [] }),
        fetchItemRecommendations(sdk.iaiRecommendations, identityId, requestedItemId, requestedType),
    ])

    const localViolations = checkPoliciesAgainstEntitlements(combinedEntitlements, policies)
    const recommendationStrings = formatRecommendations(recommendations)
    const predictedPolicyNames = parseViolatedPolicyNames(predictedViolations)

    return {
        iscRiskName: extractIscRiskName(accessModelMetadata),
        xdrScore: formatOutlierScore(xdrData),
        sodPrediction: formatSodPredictionFromPredictResponse(predictedPolicyNames),
        violatedPolicyNames: formatViolatedPolicyNames(localViolations, accessRequestStatus),
        recommendationsDecision: recommendationStrings.recommendationsDecision,
        recommendationsInterpretations: recommendationStrings.recommendationsInterpretations,
        accessRequestStatus,
        xdrData,
    }
}
