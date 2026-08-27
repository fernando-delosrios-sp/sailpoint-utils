import { describe, expect, it } from 'vitest'
import { parsePolicyQuerySides } from './parse-policy-query'
import { resolvePolicySides } from './resolve-policy-sides'
import { resolvePolicyOwnerId } from './resolve-policy-owner'
import { SodPolicySummary } from './types'

describe('parsePolicyQuerySides', () => {
    it('parses AND-separated sides with OR within each side', () => {
        const result = parsePolicyQuerySides(
            '@access(id:ent-a OR id:ent-b) AND @access(id:ent-c OR id:ent-d)'
        )
        expect(result).toEqual({
            groupAIds: ['ent-a', 'ent-b'],
            groupBIds: ['ent-c', 'ent-d'],
        })
    })

    it('returns null for unparseable query', () => {
        expect(parsePolicyQuerySides('invalid query')).toBeNull()
    })
})

describe('resolvePolicySides', () => {
    it('falls back to conflictingAccessCriteria when policyQuery is missing', () => {
        const policy: SodPolicySummary = {
            id: 'p1',
            name: 'Policy',
            conflictingAccessCriteria: {
                leftCriteria: { criteriaList: [{ id: 'ent-a', type: 'ENTITLEMENT' }] },
                rightCriteria: { criteriaList: [{ id: 'ent-c', type: 'ENTITLEMENT' }] },
            },
        }
        expect(resolvePolicySides(policy)).toEqual({
            groupAIds: ['ent-a'],
            groupBIds: ['ent-c'],
        })
    })
})

describe('resolvePolicyOwnerId', () => {
    it('returns identity owner id', () => {
        expect(
            resolvePolicyOwnerId({
                id: 'p1',
                name: 'Policy',
                ownerRef: { type: 'IDENTITY', id: 'owner-1' },
            })
        ).toBe('owner-1')
    })
})
