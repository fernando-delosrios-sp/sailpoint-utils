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
