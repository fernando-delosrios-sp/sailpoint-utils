const RISK_PERSIST_IDENTITY_PREFIX = 'evaluate-access-request-risk:'

/**
 * Builds the risk persist identity for a result account from the invoke `requestId`.
 * Idempotent: a `requestId` that already carries the prefix is returned unchanged, so an
 * operator re-importing workflows mid-rollout cannot write a double-prefixed orphan account.
 */
export function riskPersistIdentity(requestId: string): string {
    return requestId.startsWith(RISK_PERSIST_IDENTITY_PREFIX)
        ? requestId
        : `${RISK_PERSIST_IDENTITY_PREFIX}${requestId}`
}
