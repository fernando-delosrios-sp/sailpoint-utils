import type { AccessRequestAnalytics, ApprovalEmailContext } from './types'

export function buildApprovalEmailBody(analytics: AccessRequestAnalytics, context: ApprovalEmailContext): string {
    return `<p>Dear ${context.managerRefName},</p>
<p>Please <strong><span style="background-color: #2dc26b;">APPROVE</span></strong> or <span style="background-color: #e03e2d;"><strong>DENY</strong></span> access request from ${context.displayName} with request id ${context.accessRequestId}. This request has passed preliminary approval with ${analytics.iscRiskName} Risk.</p>
<ul>
<li>Outlier score: ${analytics.xdrScore}</li>
<li>ISC risk: ${analytics.iscRiskName}</li>
<li>Violated policies:
<ul>
<li>${analytics.sodPrediction}</li>
</ul>
</li>
<li>Potential violation with pending access requests:
<ul>
<li>${analytics.violatedPolicyNames}</li>
</ul>
</li>
<li>Recommendations:
<ul>
<li>${analytics.recommendationsDecision}</li>
<li>${analytics.recommendationsInterpretations}</li>
</ul>
</li>
</ul>
<p>For governance reasons, please log on to <a title="ISC Approval Center" href="https://company23429-poc.identitynow-demo.com/ui/d/approvals/requested-items" target="_blank" rel="noopener noreferrer">ISC Approval Center</a> and use this information for a better quality for your decision.</p>
<p>Thank you very much. Sincerely,</p>
<p>SailPoint Identity Security Cloud Team.</p>`
}
