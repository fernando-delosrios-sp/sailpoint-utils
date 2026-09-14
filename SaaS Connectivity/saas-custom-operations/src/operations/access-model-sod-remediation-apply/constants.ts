/** Builds the apply persist identity for a form instance result account. */
export function applyPersistIdentity(formInstanceId: string): string {
    return `access-model-sod-remediation-apply:${formInstanceId}`
}
