import { type IscClientConfig, iscGet } from '../http'
import { listActiveViolationPolicyNamesForIdentityOffline } from './offline-data'

interface ViolationListEntry {
    policy?: { name?: string }
}

function appendUniquePolicyNames(names: string[], seen: Set<string>, entry: ViolationListEntry): void {
    const name = entry.policy?.name
    if (!name || seen.has(name)) {
        return
    }
    seen.add(name)
    names.push(name)
}

/** Lists policy names from active SoD violations for an identity via GET /violations/v1. */
export async function listActiveViolationPolicyNamesForIdentity(
    config: IscClientConfig,
    identityId: string
): Promise<string[]> {
    const filter = encodeURIComponent(`identityId eq "${identityId}"`)
    const raw = await iscGet<ViolationListEntry[] | { items?: ViolationListEntry[] }>(
        config,
        `/violations/v1?filters=${filter}&limit=250`,
        { experimental: true }
    )

    const entries = Array.isArray(raw) ? raw : (raw.items ?? [])
    const names: string[] = []
    const seen = new Set<string>()
    for (const entry of entries) {
        appendUniquePolicyNames(names, seen, entry)
    }
    return names
}

export { listActiveViolationPolicyNamesForIdentityOffline }
