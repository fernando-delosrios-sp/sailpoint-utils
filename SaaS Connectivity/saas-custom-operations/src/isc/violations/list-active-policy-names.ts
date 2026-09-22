import { type IscClientConfig, iscGet } from '../http'
import { type PolicyNameRef } from './policy-name-sets'

interface ViolationListEntry {
    policy?: { id?: string; name?: string; level?: string }
}

function appendUniquePolicies(policies: PolicyNameRef[], seen: Set<string>, entry: ViolationListEntry): void {
    const name = entry.policy?.name
    if (!name || seen.has(name)) {
        return
    }
    seen.add(name)
    policies.push({
        ...(entry.policy?.id ? { id: entry.policy.id } : {}),
        name,
        ...(entry.policy?.level ? { level: entry.policy.level } : {}),
    })
}

/** Lists policies from active SoD violations for an identity via GET /violations/v1. */
export async function listActiveViolationPoliciesForIdentity(
    config: IscClientConfig,
    identityId: string
): Promise<PolicyNameRef[]> {
    const filter = encodeURIComponent(`identityId eq "${identityId}"`)
    const raw = await iscGet<ViolationListEntry[] | { items?: ViolationListEntry[] }>(
        config,
        `/violations/v1?filters=${filter}&limit=250`,
        { experimental: true }
    )

    const entries = Array.isArray(raw) ? raw : (raw.items ?? [])
    const policies: PolicyNameRef[] = []
    const seen = new Set<string>()
    for (const entry of entries) {
        appendUniquePolicies(policies, seen, entry)
    }
    return policies
}

/** Lists policy names from active SoD violations for an identity via GET /violations/v1. */
export async function listActiveViolationPolicyNamesForIdentity(
    config: IscClientConfig,
    identityId: string
): Promise<string[]> {
    const policies = await listActiveViolationPoliciesForIdentity(config, identityId)
    return policies.map((policy) => policy.name)
}

export { listActiveViolationPoliciesForIdentityOffline, listActiveViolationPolicyNamesForIdentityOffline } from './offline-data'
