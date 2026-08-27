import { describe, expect, it } from 'vitest'
import { resolveAccessProfileOwnerId } from './resolve-access-profile-owner'

describe('resolveAccessProfileOwnerId', () => {
    it('Access profile owner identity extraction', () => {
        expect(resolveAccessProfileOwnerId('ap-v', { type: 'IDENTITY', id: 'item-owner-2' })).toBe(
            'item-owner-2'
        )
        expect(resolveAccessProfileOwnerId('ap-v', { id: 'item-owner-2' })).toBe('item-owner-2')
    })

    it('Missing access profile owner fails', () => {
        expect(() => resolveAccessProfileOwnerId('ap-v', undefined)).toThrow(
            /Access profile ap-v has no owner.id/
        )
        expect(() => resolveAccessProfileOwnerId('ap-v', {})).toThrow(/Access profile ap-v has no owner.id/)
    })

    it('Non-IDENTITY access profile owner fails', () => {
        expect(() => resolveAccessProfileOwnerId('ap-v', { type: 'GOVERNANCE_GROUP', id: 'gg-1' })).toThrow(
            /IDENTITY required/
        )
    })
})
