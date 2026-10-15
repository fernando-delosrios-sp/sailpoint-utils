import { TaggedObjectsApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { TaggedObjectRef } from './types'

export const TAG_BATCH_SIZE = 50
const MERGE_OPERATION = 'MERGE' as const

function chunk<T>(items: readonly T[], size: number): T[][] {
    const batches: T[][] = []
    for (let i = 0; i < items.length; i += size) {
        batches.push(items.slice(i, i + size))
    }
    return batches
}

/** Adds tags to objects with MERGE (duplicates ignored). Returns number of object refs submitted. */
export async function bulkAddTags(
    taggedObjects: TaggedObjectsApi,
    objectRefs: readonly TaggedObjectRef[],
    tags: readonly string[]
): Promise<number> {
    if (objectRefs.length === 0 || tags.length === 0) {
        return 0
    }

    let submitted = 0
    try {
        for (const batch of chunk(objectRefs, TAG_BATCH_SIZE)) {
            logIscDebug('bulkAddTags setTagsToManyObjectsV1', {
                objectCount: batch.length,
                tags,
            })
            await taggedObjects.setTagsToManyObjectsV1({
                bulkAddTaggedObject: {
                    objectRefs: batch.map((ref) => ({ type: ref.type, id: ref.id })),
                    tags: [...tags],
                    operation: MERGE_OPERATION,
                },
            })
            submitted += batch.length
        }
        return submitted
    } catch (error) {
        logIscRequestFailure('bulkAddTags setTagsToManyObjectsV1', error)
        throw toConnectorError(error, `Failed to add tags [${tags.join(', ')}]`)
    }
}

/** Removes tags from objects. Returns number of object refs submitted. */
export async function bulkRemoveTags(
    taggedObjects: TaggedObjectsApi,
    objectRefs: readonly TaggedObjectRef[],
    tags: readonly string[]
): Promise<number> {
    if (objectRefs.length === 0 || tags.length === 0) {
        return 0
    }

    let submitted = 0
    try {
        for (const batch of chunk(objectRefs, TAG_BATCH_SIZE)) {
            logIscDebug('bulkRemoveTags deleteTagsToManyObjectV1', {
                objectCount: batch.length,
                tags,
            })
            await taggedObjects.deleteTagsToManyObjectV1({
                bulkRemoveTaggedObject: {
                    objectRefs: batch.map((ref) => ({ type: ref.type, id: ref.id })),
                    tags: [...tags],
                },
            })
            submitted += batch.length
        }
        return submitted
    } catch (error) {
        logIscRequestFailure('bulkRemoveTags deleteTagsToManyObjectV1', error)
        throw toConnectorError(error, `Failed to remove tags [${tags.join(', ')}]`)
    }
}
