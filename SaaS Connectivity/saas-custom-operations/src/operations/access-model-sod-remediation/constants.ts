export const DEFAULT_SCOPE = '*'
export const DEFAULT_SEARCH_INDICES = ['accessprofiles', 'roles'] as const
export const DEFAULT_POLICY_SCOPE = 'state eq "ENFORCED"'
export const MAX_FORMS_PER_RUN = 100

export type SearchIndex = (typeof DEFAULT_SEARCH_INDICES)[number]

export const VALID_SEARCH_INDICES = new Set<string>(DEFAULT_SEARCH_INDICES)

/** Builds child persist identity for a form result account. */
export function childPersistIdentity(requestId: string, accessItemId: string, policyId: string): string {
    return `${requestId}:${accessItemId}:${policyId}`
}

/** Builds the apply persist identity: invoke `requestId` plus form instance id. */
export function applyPersistIdentity(requestId: string, formInstanceId: string): string {
    return `${requestId}:${formInstanceId}`
}

/** Result-source identity written before persist used `{requestId}:{formInstanceId}`. */
export function legacyPrefixedApplyPersistIdentity(formInstanceId: string): string {
    return `access-model-sod-remediation-apply:${formInstanceId}`
}
