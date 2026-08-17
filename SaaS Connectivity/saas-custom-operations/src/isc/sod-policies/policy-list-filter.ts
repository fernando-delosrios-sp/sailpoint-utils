export type SodPolicyState = 'ENFORCED' | 'NOT_ENFORCED'

/** Parses `state eq "ENFORCED"` / `state eq "NOT_ENFORCED"` policy scope filters. */
export function parseStatePolicyFilter(filters?: string): SodPolicyState | undefined {
    if (!filters) {
        return undefined
    }

    const match = filters.trim().match(/^state\s+eq\s+"?(ENFORCED|NOT_ENFORCED)"?$/i)
    if (!match) {
        return undefined
    }

    return match[1].toUpperCase() as SodPolicyState
}

/**
 * Some tenants reject `state` as a list API filter field even though SDK docs list it.
 * When scope is state-only, list all policies and filter client-side instead.
 */
export function resolveSodPolicyListFilters(filters?: string): {
    apiFilters?: string
    clientState?: SodPolicyState
} {
    const clientState = parseStatePolicyFilter(filters)
    if (clientState) {
        return { clientState }
    }

    if (filters && /\bstate\b/i.test(filters)) {
        return { clientState: undefined, apiFilters: undefined }
    }

    return filters ? { apiFilters: filters } : {}
}

export function matchesClientStateFilter(state: SodPolicyState | undefined, required?: SodPolicyState): boolean {
    if (!required) {
        return true
    }
    return state === required
}
