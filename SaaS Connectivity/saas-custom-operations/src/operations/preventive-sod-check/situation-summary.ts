export interface PreventiveViolatedPolicy {
    name: string
    level?: string
}

export interface PreventiveSituationSummaryInput {
    violatedPolicies: PreventiveViolatedPolicy[]
    accessRequestId?: string
}

function displayPolicyLevel(level?: string): string | undefined {
    const trimmed = level?.trim()
    if (!trimmed) {
        return undefined
    }

    return trimmed.charAt(0).toUpperCase() + trimmed.slice(1).toLowerCase()
}

function formatPolicyLabel(policy: PreventiveViolatedPolicy): string {
    const level = displayPolicyLevel(policy.level)
    return level ? `${policy.name} (${level})` : policy.name
}

/** Builds plain-text preventive SoD situation summary for workflow branching. */
export function buildPreventiveSituationSummary(input: PreventiveSituationSummaryInput): string {
    const { violatedPolicies, accessRequestId } = input

    if (violatedPolicies.length === 0) {
        return 'No violations found'
    }

    const policyList = violatedPolicies.map(formatPolicyLabel).join(', ')

    if (accessRequestId) {
        return `Access request ${accessRequestId} would violate SoD policies if completed: ${policyList}`
    }

    return `SoD policy violations found: ${policyList}`
}
