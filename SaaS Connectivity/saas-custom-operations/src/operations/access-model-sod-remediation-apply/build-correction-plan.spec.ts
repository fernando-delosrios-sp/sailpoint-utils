import { describe, expect, it } from 'vitest'
import { ExpandedAccessItemEntitlements } from '../access-model-sod-remediation/expand-access-item-entitlements'
import { buildCorrectionPlan, isCorrectionPlanEmpty } from './build-correction-plan'
import { ParsedFormInstance } from './parse-form-instance'

const roleExpanded: ExpandedAccessItemEntitlements = {
    entitlementIds: new Set(['ent-a', 'ent-c']),
    entitlements: [
        { id: 'ent-a', name: 'Accounts Receivable' },
        { id: 'ent-c', name: 'Accounts Payable' },
    ],
    nestedProfiles: [
        {
            id: 'ap-x',
            name: 'SAP Suite',
            entitlements: [{ id: 'ent-c', name: 'Accounts Payable' }],
        },
    ],
}

const baseParsed: ParsedFormInstance = {
    formInstanceId: 'fi-1',
    accessItemId: 'role-r',
    accessItemType: 'ROLE',
    policyId: 'pol-1',
    policyName: 'Finance vs AP',
    remediationSide: 'groupA',
    groupAIds: ['ent-a'],
    groupBIds: ['ent-c'],
}

describe('buildCorrectionPlan', () => {
    it('Direct entitlement removed from role', () => {
        const plan = buildCorrectionPlan(baseParsed, roleExpanded)

        expect(plan.removedEntitlementIds).toEqual(['ent-a'])
        expect(plan.detachedAccessProfileIds).toEqual([])
    })

    it('Nested access profile detached from role', () => {
        const plan = buildCorrectionPlan(
            { ...baseParsed, remediationSide: 'groupB' },
            roleExpanded
        )

        expect(plan.detachedAccessProfileIds).toEqual(['ap-x'])
        expect(plan.removedEntitlementIds).toEqual([])
        expect(plan.detachedAccessProfileDetails[0]?.offendingEntitlementNames).toEqual(['Accounts Payable'])
    })

    it('Entitlements removed from access profile under review', () => {
        const apExpanded: ExpandedAccessItemEntitlements = {
            entitlementIds: new Set(['ent-x', 'ent-y']),
            entitlements: [
                { id: 'ent-x', name: 'X' },
                { id: 'ent-y', name: 'Y' },
            ],
            nestedProfiles: [],
        }

        const plan = buildCorrectionPlan(
            {
                ...baseParsed,
                accessItemId: 'ap-v',
                accessItemType: 'ACCESS_PROFILE',
                groupAIds: ['ent-x'],
                groupBIds: ['ent-y'],
            },
            apExpanded
        )

        expect(plan.removedEntitlementIds).toEqual(['ent-x'])
        expect(plan.detachedAccessProfileIds).toEqual([])
    })

    it('isCorrectionPlanEmpty is true when side entitlements are already absent', () => {
        const emptyExpanded: ExpandedAccessItemEntitlements = {
            entitlementIds: new Set(['ent-b']),
            entitlements: [{ id: 'ent-b' }],
            nestedProfiles: [],
        }

        const plan = buildCorrectionPlan(baseParsed, emptyExpanded)
        expect(isCorrectionPlanEmpty(plan)).toBe(true)
    })
})
