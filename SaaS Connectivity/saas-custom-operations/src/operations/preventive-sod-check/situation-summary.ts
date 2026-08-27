export interface PreventiveSituationSummaryInput {
    violatedPolicyNames: string[]
    accessRequestId?: string
}

/** Builds plain-text preventive SoD situation summary for workflow branching. */
export function buildPreventiveSituationSummary(input: PreventiveSituationSummaryInput): string {
    const { violatedPolicyNames, accessRequestId } = input

    if (violatedPolicyNames.length === 0) {
        return 'No violations found'
    }

    const policyList = violatedPolicyNames.join(', ')

    if (accessRequestId) {
        return `Access request ${accessRequestId} would violate SoD policies if completed: ${policyList}`
    }

    return `SoD policy violations found: ${policyList}`
}
