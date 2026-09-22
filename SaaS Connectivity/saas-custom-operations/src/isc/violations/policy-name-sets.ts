/** Merges policy name lists preserving first-seen order without duplicates. */
export function unionPolicyNames(...lists: string[][]): string[] {
    const seen = new Set<string>()
    const merged: string[] = []

    for (const list of lists) {
        for (const name of list) {
            if (seen.has(name)) {
                continue
            }
            seen.add(name)
            merged.push(name)
        }
    }

    return merged
}

/** Returns policy names present in full but not in baseline (predict delta). */
export function deltaPolicyNames(full: string[], baseline: string[]): string[] {
    const baselineSet = new Set(baseline)
    return full.filter((name) => !baselineSet.has(name))
}

export interface PolicyNameRef {
    name: string
    id?: string
    level?: string
}

function mergePolicy(existing: PolicyNameRef, incoming: PolicyNameRef): PolicyNameRef {
    return {
        name: existing.name,
        id: existing.id ?? incoming.id,
        level: existing.level ?? incoming.level,
    }
}

/** Merges policy lists by name, preserving first-seen order and filling missing id/level. */
export function unionPolicies(...lists: PolicyNameRef[][]): PolicyNameRef[] {
    const byName = new Map<string, PolicyNameRef>()
    const order: string[] = []

    for (const list of lists) {
        for (const policy of list) {
            const existing = byName.get(policy.name)
            if (!existing) {
                byName.set(policy.name, { ...policy })
                order.push(policy.name)
                continue
            }
            byName.set(policy.name, mergePolicy(existing, policy))
        }
    }

    return order.map((name) => byName.get(name)!)
}

/** Returns policies present in full but not in baseline, compared by name. */
export function deltaPolicies(full: PolicyNameRef[], baseline: PolicyNameRef[]): PolicyNameRef[] {
    const baselineNames = new Set(baseline.map((policy) => policy.name))
    return full.filter((policy) => !baselineNames.has(policy.name))
}
