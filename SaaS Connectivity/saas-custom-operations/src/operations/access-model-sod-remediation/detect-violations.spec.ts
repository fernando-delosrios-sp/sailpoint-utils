import { describe, expect, it } from 'vitest'
import { detectAccessItemViolations } from './detect-violations'
import { CatalogAccessItem } from '../../isc/roles/list-enabled-roles'
import { SodPolicySummary } from '../../isc/sod-policies'

describe('detectAccessItemViolations', () => {
    const accessItem: CatalogAccessItem = {
        id: 'role-1',
        name: 'Finance Role',
        type: 'ROLE',
    }

    const policy: SodPolicySummary = {
        id: 'policy-1',
        name: 'AP/AR Separation',
        policyQuery: '@access(id:ent-a) AND @access(id:ent-c)',
    }

    it('flags violation when both sides intersect', () => {
        const expanded = {
            entitlementIds: new Set(['ent-a', 'ent-c']),
            entitlements: [{ id: 'ent-a' }, { id: 'ent-c' }],
            nestedProfiles: [],
        }

        const violations = detectAccessItemViolations(accessItem, expanded, [policy])
        expect(violations).toHaveLength(1)
        expect(violations[0].groupAIds).toEqual(['ent-a'])
        expect(violations[0].groupBIds).toEqual(['ent-c'])
    })

    it('does not flag when only one side matches', () => {
        const expanded = {
            entitlementIds: new Set(['ent-a']),
            entitlements: [{ id: 'ent-a' }],
            nestedProfiles: [],
        }

        expect(detectAccessItemViolations(accessItem, expanded, [policy])).toHaveLength(0)
    })
})
