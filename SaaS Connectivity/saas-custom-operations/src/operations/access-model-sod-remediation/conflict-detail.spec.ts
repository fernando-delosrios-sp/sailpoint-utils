import { describe, expect, it } from 'vitest'
import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { buildConflictDetail, buildSideEntitlements } from './conflict-detail'
import { AccessItemViolation } from './detect-violations'
import { ExpandedAccessItemEntitlements } from './expand-access-item-entitlements'

function expansion(entitlements: Array<{ id: string; name?: string }>): ExpandedAccessItemEntitlements {
    return {
        entitlementIds: new Set(entitlements.map((entitlement) => entitlement.id)),
        entitlements,
        nestedProfiles: [],
    }
}

function violation(overrides: Partial<AccessItemViolation> = {}): AccessItemViolation {
    return {
        accessItem: {
            id: 'role-a',
            name: 'Accounts Payable Analyst',
            type: 'ROLE',
        } as AccessItemViolation['accessItem'],
        policy: { id: 'policy-p', name: 'AP settlement vs payment release' } as AccessItemViolation['policy'],
        groupAIds: ['ent-1'],
        groupBIds: ['ent-2'],
        ...overrides,
    }
}

describe('buildSideEntitlements', () => {
    it('Side named: comma-separates the display names on that side', () => {
        const value = buildSideEntitlements(
            ['ent-1', 'ent-2'],
            expansion([
                { id: 'ent-1', name: 'Invoice Entry' },
                { id: 'ent-2', name: 'Payment Release' },
            ])
        )

        expect(value).toBe('Invoice Entry, Payment Release')
    })

    it('Unnamed entitlement falls back to its id', () => {
        expect(buildSideEntitlements(['ent-1'], expansion([{ id: 'ent-1' }]))).toBe('ent-1')
    })

    it('Empty side reads as none rather than an empty value', () => {
        expect(buildSideEntitlements([], expansion([]))).toBe('none')
    })

    it('Long list drops whole names and counts them within the ISC ceiling', () => {
        // Distinct prefixes so a partial match cannot be mistaken for a sibling's name.
        const names = Array.from({ length: 20 }, (_, index) => ({
            id: `ent-${index}`,
            name: `${String.fromCharCode(65 + index)}-Finance Operations Entitlement`,
        }))
        const value = buildSideEntitlements(
            names.map((entitlement) => entitlement.id),
            expansion(names)
        )

        expect(value.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(value).toMatch(/ \+\d+ more$/)
        for (const entitlement of names) {
            const mentioned = value.includes(entitlement.name)
            const partial = !mentioned && value.includes(entitlement.name.slice(0, 20))
            expect(partial).toBe(false)
        }
    })

    it('A side may spend the whole ceiling rather than half of it', () => {
        const value = buildSideEntitlements(['ent-1'], expansion([{ id: 'ent-1', name: 'A'.repeat(240) }]))

        expect(value).toBe('A'.repeat(240))
    })

    it('Name longer than the ceiling degrades to the side count', () => {
        const value = buildSideEntitlements(
            ['ent-1', 'ent-2'],
            expansion([
                { id: 'ent-1', name: 'A'.repeat(300) },
                { id: 'ent-2', name: 'B'.repeat(300) },
            ])
        )

        expect(value).toBe('2 entitlements')
    })
})

describe('buildConflictDetail', () => {
    it('Identity fields persisted verbatim with each policy side on its own attribute', () => {
        const detail = buildConflictDetail({
            violation: violation(),
            expanded: expansion([
                { id: 'ent-1', name: 'Invoice Entry' },
                { id: 'ent-2', name: 'Payment Release' },
            ]),
            recipientId: 'owner-1',
        })

        expect(detail).toEqual({
            'access-model-sod-remediation:access-item-id': 'role-a',
            'access-model-sod-remediation:access-item-type': 'ROLE',
            'access-model-sod-remediation:access-item-name': 'Accounts Payable Analyst',
            'access-model-sod-remediation:policy-id': 'policy-p',
            'access-model-sod-remediation:policy-name': 'AP settlement vs payment release',
            'access-model-sod-remediation:recipient-id': 'owner-1',
            'access-model-sod-remediation:conflicting-entitlements-group-a': 'Invoice Entry',
            'access-model-sod-remediation:conflicting-entitlements-group-b': 'Payment Release',
        })
    })

    it('Missing names fall back to ids so no attribute is empty', () => {
        const detail = buildConflictDetail({
            violation: violation({
                accessItem: { id: 'role-a', type: 'ROLE' } as AccessItemViolation['accessItem'],
                policy: { id: 'policy-p' } as AccessItemViolation['policy'],
            }),
            expanded: expansion([{ id: 'ent-1' }, { id: 'ent-2' }]),
            recipientId: 'owner-1',
        })

        expect(detail['access-model-sod-remediation:access-item-name']).toBe('role-a')
        expect(detail['access-model-sod-remediation:policy-name']).toBe('policy-p')
    })

    it('Definition links point at the access item kind and SoD policy', () => {
        const detail = buildConflictDetail({
            violation: violation(),
            expanded: expansion([{ id: 'ent-1' }, { id: 'ent-2' }]),
            recipientId: 'owner-1',
            uiOrigin: 'https://tenant.identitynow-demo.com',
        })

        expect(detail['access-model-sod-remediation:access-item-url']).toBe(
            'https://tenant.identitynow-demo.com/ui/a/admin/access/roles/landing-page/details/role-a'
        )
        expect(detail['access-model-sod-remediation:policy-url']).toBe(
            'https://tenant.identitynow-demo.com/ui/sod/policy-management/policy-p/details'
        )
    })
})
