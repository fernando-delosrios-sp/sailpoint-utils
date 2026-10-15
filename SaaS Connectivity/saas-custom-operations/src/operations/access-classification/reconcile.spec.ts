import { describe, expect, it } from 'vitest'
import { ACCESS_ITEM_TYPES, SOD_RECONCILE_TYPES } from './constants'
import { buildTagDiffs, diffTagHolders } from './reconcile'

describe('diffTagHolders', () => {
    it('computes add and remove sets', () => {
        const diff = diffTagHolders(
            'privileged',
            new Set(['ENTITLEMENT:ent-1', 'ACCESS_PROFILE:ap-1']),
            [
                { type: 'ENTITLEMENT', id: 'ent-1' },
                { type: 'ROLE', id: 'role-stale' },
            ],
            ACCESS_ITEM_TYPES
        )

        expect(diff.toAdd).toEqual([{ type: 'ACCESS_PROFILE', id: 'ap-1' }])
        expect(diff.toRemove).toEqual([{ type: 'ROLE', id: 'role-stale' }])
    })
})

describe('buildTagDiffs', () => {
    it('omits tags with no changes', () => {
        const desired = new Map([['risk', new Set(['ENTITLEMENT:ent-1'])]])
        const current = new Map([
            ['risk', [{ type: 'ENTITLEMENT' as const, id: 'ent-1' }]],
            ['privileged', []],
        ])

        const diffs = buildTagDiffs(desired, new Set(['risk', 'privileged']), current, () => ACCESS_ITEM_TYPES)

        expect(diffs).toHaveLength(0)
    })

    it('includes SOD identity reconciles', () => {
        const desired = new Map([['SOD_A', new Set(['IDENTITY:ident-1'])]])
        const current = new Map([['SOD_A', [{ type: 'IDENTITY' as const, id: 'ident-old' }]]])

        const diffs = buildTagDiffs(desired, new Set(['SOD_A']), current, () => SOD_RECONCILE_TYPES)

        expect(diffs).toHaveLength(1)
        expect(diffs[0].toAdd).toEqual([{ type: 'IDENTITY', id: 'ident-1' }])
        expect(diffs[0].toRemove).toEqual([{ type: 'IDENTITY', id: 'ident-old' }])
    })
})
