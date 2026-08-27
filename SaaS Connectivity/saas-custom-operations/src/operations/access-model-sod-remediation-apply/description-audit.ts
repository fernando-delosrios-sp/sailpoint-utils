import { RemediationSide } from './parse-form-instance'
import { DetachedAccessProfileDetail, RemovedEntitlementDetail } from './build-correction-plan'

export interface DescriptionAuditInput {
    policyName: string
    policyId: string
    remediationSide: RemediationSide
    formInstanceId: string
    detachedProfiles: DetachedAccessProfileDetail[]
    removedEntitlements: RemovedEntitlementDetail[]
    comments?: string
    submitterId?: string
    timestamp?: string
}

/** Builds a human-readable description audit line for catalog correction. */
export function buildDescriptionAuditLine(input: DescriptionAuditInput): string {
    const timestamp = input.timestamp ?? new Date().toISOString()
    const sideLabel = input.remediationSide === 'groupA' ? 'Group A' : 'Group B'
    const detailParts: string[] = []

    for (const profile of input.detachedProfiles) {
        detailParts.push(
            `detached access profile "${profile.name}" (${profile.id}) — offending: ${profile.offendingEntitlementNames.join(', ')}`
        )
    }

    if (input.removedEntitlements.length > 0) {
        const labels = input.removedEntitlements.map((entitlement) =>
            entitlement.name ? `"${entitlement.name}" (${entitlement.id})` : entitlement.id
        )
        detailParts.push(`removed direct entitlements: ${labels.join(', ')}`)
    }

    let line = `[SOD remediation ${timestamp}] Policy "${input.policyName}" (${input.policyId}): corrected ${sideLabel} side`
    if (detailParts.length > 0) {
        line += ` — ${detailParts.join('; ')}`
    }
    line += `; form instance ${input.formInstanceId}`
    if (input.submitterId) {
        line += `; submitter ${input.submitterId}`
    }
    if (input.comments) {
        line += `; comments: ${input.comments}`
    }
    return line
}
