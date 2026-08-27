/** Canned active violation policy names for offline preventive SoD checks. */
export function listActiveViolationPolicyNamesForIdentityOffline(identityId: string): string[] {
    if (identityId === 'offline-preventive-existing') {
        return ['Existing Control']
    }
    return []
}
