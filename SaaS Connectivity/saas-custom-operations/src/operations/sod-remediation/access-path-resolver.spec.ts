import { describe, expect, it } from 'vitest'
import { resolveAccessSide } from './access-path-resolver'

describe('access-path-resolver', () => {
    it('entitlement-only side produces revocable entitlement and standard warning', () => {
        const result = resolveAccessSide([{ id: 'ent-1', name: 'Finance Ledger' }], [])

        expect(result.displayLines).toEqual(['Entitlement: Finance Ledger'])
        expect(result.accessPaths).toEqual([
            {
                type: 'ENTITLEMENT',
                id: 'ent-1',
                name: 'Finance Ledger',
                revocable: true,
                recommended: false,
                reason: 'direct-assignment',
            },
        ])
        expect(result.warningText).toContain('Select the side whose access should be removed')
        expect(result.revokePayload.recommendedRevoke).toMatchObject({
            type: 'ENTITLEMENT',
            id: 'ent-1',
            revocable: true,
        })
    })

    it('AP-granted entitlement marks entitlement not revocable with grantedVia access profile', () => {
        const result = resolveAccessSide(
            [{ id: 'ent-1', name: 'Finance Ledger' }],
            [{ type: 'ACCESS_PROFILE', id: 'ap-1', name: 'Finance AP', grantedEntitlementIds: ['ent-1'] }]
        )

        expect(result.accessPaths[0]).toMatchObject({
            type: 'ENTITLEMENT',
            revocable: false,
            recommended: false,
            reason: 'granted-via-access-profile',
            grantedVia: { type: 'ACCESS_PROFILE', id: 'ap-1', name: 'Finance AP' },
        })
        expect(result.accessPaths[1]).toMatchObject({
            type: 'ACCESS_PROFILE',
            revocable: true,
            recommended: false,
        })
        expect(result.warningText).toContain('profile- or role-level access')
        expect(result.revokePayload.recommendedRevoke.type).toBe('ACCESS_PROFILE')
    })

    it('role-granted entitlement records named grantedVia role', () => {
        const result = resolveAccessSide(
            [{ id: 'ent-1', name: 'Finance Ledger' }],
            [{ type: 'ROLE', id: 'role-1', name: 'B2B Buyer', grantedEntitlementIds: ['ent-1'] }]
        )

        expect(result.accessPaths[0]).toMatchObject({
            type: 'ENTITLEMENT',
            revocable: false,
            reason: 'granted-via-role',
            grantedVia: { type: 'ROLE', id: 'role-1', name: 'B2B Buyer' },
        })
        expect(result.accessPaths[1]).toMatchObject({
            type: 'ROLE',
            revocable: true,
            recommended: false,
        })
    })

    it('recommendedRevoke prefers Role over Access Profile over Entitlement among revocable items', () => {
        const result = resolveAccessSide(
            [{ id: 'ent-1', name: 'Finance Ledger' }],
            [
                { type: 'ACCESS_PROFILE', id: 'ap-1', name: 'Finance AP', grantedEntitlementIds: ['ent-1'] },
                { type: 'ROLE', id: 'role-1', name: 'Finance Role', grantedEntitlementIds: ['ent-1'] },
            ]
        )

        expect(result.revokePayload.recommendedRevoke).toMatchObject({
            type: 'ROLE',
            id: 'role-1',
            revocable: true,
        })
        expect(result.accessPaths.find((line) => line.type === 'ENTITLEMENT')).toMatchObject({
            revocable: false,
            reason: 'granted-via-role',
            grantedVia: { type: 'ROLE', id: 'role-1', name: 'Finance Role' },
        })
    })
})
