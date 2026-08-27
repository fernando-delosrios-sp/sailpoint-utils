import { describe, expect, it } from 'vitest'
import { buildSkippedFormInstance } from './skipped-form-instance'

describe('buildSkippedFormInstance', () => {
    it('includes child identity and violation context only', () => {
        expect(
            buildSkippedFormInstance('scan-1:role-1:policy-1', {
                accessItem: { id: 'role-1', name: 'Finance Role', type: 'ROLE' },
                policy: { id: 'policy-1', name: 'AP/AR Separation' },
                groupAIds: ['ent-a'],
                groupBIds: ['ent-c'],
            })
        ).toEqual({
            childIdentity: 'scan-1:role-1:policy-1',
            accessItemId: 'role-1',
            accessItemType: 'ROLE',
            accessItemName: 'Finance Role',
            policyId: 'policy-1',
            policyName: 'AP/AR Separation',
        })
    })
})
