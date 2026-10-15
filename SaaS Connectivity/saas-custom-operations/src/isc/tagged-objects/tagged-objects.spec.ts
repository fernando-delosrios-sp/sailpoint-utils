import { describe, expect, it, vi } from 'vitest'
import { bulkAddTags, bulkRemoveTags, TAG_BATCH_SIZE } from './bulk-tags'
import { ensureTag } from './ensure-tag'
import { listObjectsByTag } from './list-by-tag'

describe('isc/tagged-objects', () => {
    it('ensureTag creates the tag when list returns empty', async () => {
        const listTagsV1 = vi.fn().mockResolvedValue({ data: [] })
        const createTagV1 = vi.fn().mockResolvedValue({ data: { name: 'privileged' } })

        const canonical = await ensureTag({ listTagsV1, createTagV1 } as never, 'privileged')

        expect(listTagsV1).toHaveBeenCalledWith({ filters: 'name eq "privileged"', limit: 1 })
        expect(createTagV1).toHaveBeenCalledWith({ tag2: { name: 'privileged' } })
        expect(canonical).toBe('privileged')
    })

    it('ensureTag skips create when the tag already exists (case-insensitive)', async () => {
        const listTagsV1 = vi.fn().mockResolvedValue({ data: [{ name: 'PRIVILEGED' }] })
        const createTagV1 = vi.fn()

        const canonical = await ensureTag({ listTagsV1, createTagV1 } as never, 'privileged')

        expect(createTagV1).not.toHaveBeenCalled()
        expect(canonical).toBe('PRIVILEGED')
    })

    it('listObjectsByTag pages and keeps reconciled types only', async () => {
        const listTaggedObjectsV1 = vi
            .fn()
            .mockResolvedValueOnce({
                data: Array.from({ length: 250 }, (_, i) => ({
                    objectRef: { type: 'ENTITLEMENT', id: `ent-${i}` },
                })),
            })
            .mockResolvedValueOnce({
                data: [
                    { objectRef: { type: 'ROLE', id: 'role-1' } },
                    { objectRef: { type: 'SOURCE', id: 'source-1' } },
                    { objectRef: { type: 'SOD_POLICY', id: 'pol-1' } },
                ],
            })

        const refs = await listObjectsByTag({ listTaggedObjectsV1 } as never, 'privileged')

        expect(listTaggedObjectsV1).toHaveBeenCalledTimes(2)
        expect(refs).toHaveLength(251)
        expect(refs.some((ref) => ref.type === 'SOURCE')).toBe(false)
        expect(refs.some((ref) => ref.type === 'SOD_POLICY')).toBe(false)
        expect(refs).toContainEqual({ type: 'ROLE', id: 'role-1' })
    })

    it('bulkAddTags uses MERGE and batches of 50', async () => {
        const setTagsToManyObjectsV1 = vi.fn().mockResolvedValue({ data: [] })
        const refs = Array.from({ length: TAG_BATCH_SIZE + 2 }, (_, i) => ({
            type: 'ENTITLEMENT' as const,
            id: `ent-${i}`,
        }))

        const submitted = await bulkAddTags({ setTagsToManyObjectsV1 } as never, refs, ['privileged'])

        expect(submitted).toBe(refs.length)
        expect(setTagsToManyObjectsV1).toHaveBeenCalledTimes(2)
        expect(setTagsToManyObjectsV1.mock.calls[0][0].bulkAddTaggedObject.operation).toBe('MERGE')
        expect(setTagsToManyObjectsV1.mock.calls[0][0].bulkAddTaggedObject.objectRefs).toHaveLength(50)
        expect(setTagsToManyObjectsV1.mock.calls[1][0].bulkAddTaggedObject.objectRefs).toHaveLength(2)
    })

    it('bulkRemoveTags batches removals', async () => {
        const deleteTagsToManyObjectV1 = vi.fn().mockResolvedValue({})
        const refs = [{ type: 'IDENTITY' as const, id: 'ident-1' }]

        const submitted = await bulkRemoveTags({ deleteTagsToManyObjectV1 } as never, refs, ['SOD_A'])

        expect(submitted).toBe(1)
        expect(deleteTagsToManyObjectV1).toHaveBeenCalledWith({
            bulkRemoveTaggedObject: {
                objectRefs: [{ type: 'IDENTITY', id: 'ident-1' }],
                tags: ['SOD_A'],
            },
        })
    })

    it('bulkAddTags and bulkRemoveTags no-op on empty input', async () => {
        const setTagsToManyObjectsV1 = vi.fn()
        const deleteTagsToManyObjectV1 = vi.fn()

        expect(await bulkAddTags({ setTagsToManyObjectsV1 } as never, [], ['privileged'])).toBe(0)
        expect(await bulkRemoveTags({ deleteTagsToManyObjectV1 } as never, [{ type: 'ROLE', id: 'r' }], [])).toBe(0)
        expect(setTagsToManyObjectsV1).not.toHaveBeenCalled()
        expect(deleteTagsToManyObjectV1).not.toHaveBeenCalled()
    })
})
