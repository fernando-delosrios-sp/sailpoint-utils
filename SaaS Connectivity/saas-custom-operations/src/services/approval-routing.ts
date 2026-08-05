import type { AccessRequestAnalytics, EmailRoute, GetAccessRequestStatus } from './types'

const MEDIUM_RISK_PREFIX = 'This access has passed preliminary approval with Medium Risk.'

export function resolveEmailRoute(analytics: AccessRequestAnalytics): EmailRoute {
    const { iscRiskName, accessRequestStatus } = analytics
    const preApprovalComment = accessRequestStatus.preApprovalTriggerDetails?.comment ?? ''

    if (iscRiskName === 'N/A' || iscRiskName === 'Low') {
        return 'manager'
    }

    if (preApprovalComment.startsWith(MEDIUM_RISK_PREFIX) || iscRiskName === 'High') {
        return 'manager-owner'
    }

    if (iscRiskName === 'Critical') {
        return 'manager-owner-bcc'
    }

    return 'failure'
}

export function buildEtsPreApprovalComment(analytics: AccessRequestAnalytics): string {
    return [
        `This access has passed preliminary approval with ${analytics.iscRiskName} Risk.`,
        `Outlier score: ${analytics.xdrScore}`,
        `ISC risk: ${analytics.iscRiskName}`,
        `Violated policies: ${analytics.sodPrediction}`,
        `Potential violation with pending access requests: ${analytics.violatedPolicyNames}`,
        `Recommendations: ${analytics.recommendationsDecision}`,
        `[${analytics.recommendationsInterpretations}]`,
    ].join(' ')
}

export function getRequestedItemName(status: GetAccessRequestStatus): string {
    return status.name ?? 'requested access'
}
