import { describe, expect, it } from 'vitest'
import { resolveRoleOwnerId } from './resolve-role-owner'

describe('resolveRoleOwnerId', () => {
    it('Role owner identity extraction', () => {
        expect(resolveRoleOwnerId('role-r', { type: 'IDENTITY', id: 'item-owner-1' })).toBe('item-owner-1')
        expect(resolveRoleOwnerId('role-r', { id: 'item-owner-1' })).toBe('item-owner-1')
    })

    it('Missing role owner fails', () => {
        expect(() => resolveRoleOwnerId('role-r', undefined)).toThrow(/Role role-r has no owner.id/)
        expect(() => resolveRoleOwnerId('role-r', {})).toThrow(/Role role-r has no owner.id/)
    })

    it('Non-IDENTITY role owner fails', () => {
        expect(() => resolveRoleOwnerId('role-r', { type: 'GOVERNANCE_GROUP', id: 'gg-1' })).toThrow(
            /IDENTITY required/
        )
    })
})
