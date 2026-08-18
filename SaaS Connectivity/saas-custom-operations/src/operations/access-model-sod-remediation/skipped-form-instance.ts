import { AccessItemViolation } from './detect-violations'

export interface AccessModelSodSkippedFormInstance {
    childIdentity: string
    accessItemId: string
    accessItemType: string
    accessItemName: string
    policyId: string
    policyName: string
}

/** Builds global invoke-response metadata for a violation skipped by child persist idempotency. */
export function buildSkippedFormInstance(
    childIdentity: string,
    violation: AccessItemViolation
): AccessModelSodSkippedFormInstance {
    return {
        childIdentity,
        accessItemId: violation.accessItem.id,
        accessItemType: violation.accessItem.type,
        accessItemName: violation.accessItem.name,
        policyId: violation.policy.id,
        policyName: violation.policy.name,
    }
}
