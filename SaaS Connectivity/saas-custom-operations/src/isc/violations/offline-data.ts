import { type PolicyNameRef } from './policy-name-sets'

/** Canned active violation policies for offline preventive SoD checks. */
export function listActiveViolationPoliciesForIdentityOffline(identityId: string): PolicyNameRef[] {
    if (identityId === 'offline-preventive-existing') {
        return [{ name: 'Existing Control', level: 'LOW' }]
    }
    return []
}

/** Canned active violation policy names for offline preventive SoD checks. */
export function listActiveViolationPolicyNamesForIdentityOffline(identityId: string): string[] {
    return listActiveViolationPoliciesForIdentityOffline(identityId).map((policy) => policy.name)
}
