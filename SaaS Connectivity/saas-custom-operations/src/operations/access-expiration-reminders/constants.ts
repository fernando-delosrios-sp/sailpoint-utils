export const MAX_FORMS_PER_RUN = 25
export const DEFAULT_EXPIRATION_DAYS = 1

/** Builds child persist identity for an expiration notice account. */
export function childPersistIdentity(requestId: string, identityId: string, accessProfileId: string): string {
    return `${requestId}:${identityId}:${accessProfileId}`
}
