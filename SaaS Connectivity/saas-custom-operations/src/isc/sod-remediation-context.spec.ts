import { describe, expect, it } from 'vitest'
import { assembleFormInput } from './sod-remediation-context'

describe('sod-remediation-context', () => {
    it('assembleFormInput includes hidden revoke payloads as JSON strings', () => {
        const formInput = assembleFormInput({
            violation: {
                id: 'vio-1',
                owner: { id: 'owner-1' },
                identity: { id: 'ident-1', name: 'Alice' },
                policy: { id: 'pol-1', name: 'AP vs AP' },
                leftSide: { entitlements: [{ id: 'ent-a', name: 'Ent A' }] },
                rightSide: { entitlements: [{ id: 'ent-b', name: 'Ent B' }] },
            },
            groupA: {
                displayLines: ['Entitlement: Ent A'],
                warningText: 'standard',
                revokePayload: {
                    items: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' }],
                    recommendedRevoke: { type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' },
                },
            },
            groupB: {
                displayLines: ['Entitlement: Ent B', 'Role: Finance Role'],
                warningText: 'elevated',
                revokePayload: {
                    items: [
                        { type: 'ENTITLEMENT', id: 'ent-b', name: 'Ent B' },
                        { type: 'ROLE', id: 'role-1', name: 'Finance Role' },
                    ],
                    recommendedRevoke: { type: 'ROLE', id: 'role-1', name: 'Finance Role' },
                },
            },
            controls: [{ id: 'ctrl-1', name: 'Control 1' }],
        })

        expect(formInput.hasControls).toBe(true)
        expect(formInput.violationId).toBe('vio-1')
        expect(formInput.targetIdentityId).toBe('ident-1')
        expect(JSON.parse(formInput.groupARevokePayload)).toEqual({
            items: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' }],
            recommendedRevoke: { type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' },
        })
        expect(JSON.parse(formInput.groupBRevokePayload).recommendedRevoke.type).toBe('ROLE')
    })
})
