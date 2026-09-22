/** Builds the apply persist identity: invoke `requestId` plus form instance id. */
export function applyPersistIdentity(requestId: string, formInstanceId: string): string {
    return `${requestId}:${formInstanceId}`
}

/** Result-source identity written before persist used `{requestId}:{formInstanceId}`. */
export function legacyPrefixedApplyPersistIdentity(formInstanceId: string): string {
    return `access-model-sod-remediation-apply:${formInstanceId}`
}
