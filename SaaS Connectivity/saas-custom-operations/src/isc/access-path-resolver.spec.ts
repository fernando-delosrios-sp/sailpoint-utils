import { describe, expect, it } from 'vitest'
import { resolveAccessSide } from './access-path-resolver'

describe('access-path-resolver', () => {
    it('entitlement-only side produces display lines and standard warning', () => {
        const result = resolveAccessSide([{ id: 'ent-1', name: 'Finance Ledger' }], [])

        expect(result.displayLines).toEqual(['Entitlement: Finance Ledger'])
        expect(result.warningText).toContain('Select the side whose access should be removed')
        expect(result.revokePayload.recommendedRevoke).toEqual({
            type: 'ENTITLEMENT',
            id: 'ent-1',
            name: 'Finance Ledger',
        })
    })

    it('AP-granted entitlement adds AP line and elevated warning', () => {
        const result = resolveAccessSide(
            [{ id: 'ent-1', name: 'Finance Ledger' }],
            [{ type: 'ACCESS_PROFILE', id: 'ap-1', name: 'Finance AP', grantedEntitlementIds: ['ent-1'] }]
        )

        expect(result.displayLines).toEqual(['Entitlement: Finance Ledger', 'Access Profile: Finance AP'])
        expect(result.warningText).toContain('profile- or role-level access')
        expect(result.revokePayload.recommendedRevoke.type).toBe('ACCESS_PROFILE')
    })

    it('role-granted entitlement adds role line and elevated warning', () => {
        const result = resolveAccessSide(
            [{ id: 'ent-1', name: 'Finance Ledger' }],
            [{ type: 'ROLE', id: 'role-1', name: 'Finance Role', grantedEntitlementIds: ['ent-1'] }]
        )

        expect(result.displayLines).toContain('Role: Finance Role')
        expect(result.warningText).toContain('profile- or role-level access')
        expect(result.revokePayload.recommendedRevoke.type).toBe('ROLE')
    })

    it('recommendedRevoke prefers Role over Access Profile over Entitlement', () => {
        const result = resolveAccessSide(
            [{ id: 'ent-1', name: 'Finance Ledger' }],
            [
                { type: 'ENTITLEMENT', id: 'ent-1', name: 'Finance Ledger' },
                { type: 'ACCESS_PROFILE', id: 'ap-1', name: 'Finance AP', grantedEntitlementIds: ['ent-1'] },
                { type: 'ROLE', id: 'role-1', name: 'Finance Role', grantedEntitlementIds: ['ent-1'] },
            ]
        )

        expect(result.revokePayload.recommendedRevoke).toEqual({
            type: 'ROLE',
            id: 'role-1',
            name: 'Finance Role',
        })
    })
})
