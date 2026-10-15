import type { TaggedObjectRef, TaggedObjectType } from '../../isc/tagged-objects'
import { parseObjectKey, type DesiredTagMap } from './desired-tags'

export interface TagDiff {
    tag: string
    toAdd: TaggedObjectRef[]
    toRemove: TaggedObjectRef[]
}

function keyOf(ref: TaggedObjectRef): string {
    return `${ref.type}:${ref.id}`
}

/** Diffs desired holders against current holders for one tag. */
export function diffTagHolders(
    tag: string,
    desiredKeys: ReadonlySet<string>,
    currentRefs: readonly TaggedObjectRef[],
    allowedTypes: ReadonlySet<TaggedObjectType>
): TagDiff {
    const currentKeys = new Set<string>()
    for (const ref of currentRefs) {
        if (allowedTypes.has(ref.type)) {
            currentKeys.add(keyOf(ref))
        }
    }

    const toAdd: TaggedObjectRef[] = []
    for (const key of desiredKeys) {
        if (currentKeys.has(key)) {
            continue
        }
        const ref = parseObjectKey(key)
        if (ref && allowedTypes.has(ref.type)) {
            toAdd.push(ref)
        }
    }

    const toRemove: TaggedObjectRef[] = []
    for (const key of currentKeys) {
        if (desiredKeys.has(key)) {
            continue
        }
        const ref = parseObjectKey(key)
        if (ref) {
            toRemove.push(ref)
        }
    }

    return { tag, toAdd, toRemove }
}

/** Builds diffs for every managed tag. Tags with no changes are omitted. */
export function buildTagDiffs(
    desired: DesiredTagMap,
    managedTags: ReadonlySet<string>,
    currentByTag: ReadonlyMap<string, readonly TaggedObjectRef[]>,
    allowedTypesForTag: (tag: string) => ReadonlySet<TaggedObjectType>
): TagDiff[] {
    const diffs: TagDiff[] = []
    for (const tag of managedTags) {
        const diff = diffTagHolders(
            tag,
            desired.get(tag) ?? new Set(),
            currentByTag.get(tag) ?? [],
            allowedTypesForTag(tag)
        )
        if (diff.toAdd.length > 0 || diff.toRemove.length > 0) {
            diffs.push(diff)
        }
    }
    return diffs
}
