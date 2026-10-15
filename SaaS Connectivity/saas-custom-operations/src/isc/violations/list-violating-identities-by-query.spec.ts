import { describe, expect, it, vi } from 'vitest'
import {
    buildPolicyViolationSearchQuery,
    listViolatingIdentityIdsByPolicyQuery,
} from './list-violating-identities-by-query'

describe('buildPolicyViolationSearchQuery', () => {
    it('prefers policyQuery when present', () => {
        expect(
            buildPolicyViolationSearchQuery({
                id: 'pol-1',
                name: 'P',
                policyQuery: '@access(id:a) AND @access(id:b)',
            })
        ).toBe('@access(id:a) AND @access(id:b)')
    })

    it('builds a query from structured criteria when policyQuery is absent', () => {
        expect(
            buildPolicyViolationSearchQuery({
                id: 'pol-1',
                name: 'P',
                conflictingAccessCriteria: {
                    leftCriteria: {
                        criteriaList: [
                            { id: 'ent-a', type: 'ENTITLEMENT' },
                            { id: 'ent-a2', type: 'ENTITLEMENT' },
                        ],
                    },
                    rightCriteria: { criteriaList: [{ id: 'ent-b', type: 'ENTITLEMENT' }] },
                },
            })
        ).toBe('@access(id:ent-a OR id:ent-a2) AND @access(id:ent-b)')
    })
})

describe('listViolatingIdentityIdsByPolicyQuery', () => {
    it('pages identity search for the policy query', async () => {
        const searchPostV1 = vi
            .fn()
            .mockResolvedValueOnce({
                data: Array.from({ length: 250 }, (_, i) => ({ id: `ident-${i}` })),
            })
            .mockResolvedValueOnce({ data: [{ id: 'ident-last' }, { id: 'ident-0' }] })

        const ids = await listViolatingIdentityIdsByPolicyQuery(
            { searchPostV1 } as never,
            {
                id: 'pol-1',
                name: 'P',
                policyQuery: '@access(id:a) AND @access(id:b)',
            }
        )

        expect(searchPostV1).toHaveBeenCalledTimes(2)
        expect(searchPostV1.mock.calls[0][0]).toMatchObject({
            search: {
                indices: ['identities'],
                query: { query: '@access(id:a) AND @access(id:b)' },
            },
        })
        expect(ids).toHaveLength(251)
        expect(ids).toContain('ident-last')
        expect(ids.filter((id) => id === 'ident-0')).toHaveLength(1)
    })

    it('returns empty when the policy has no searchable query', async () => {
        const searchPostV1 = vi.fn()
        const ids = await listViolatingIdentityIdsByPolicyQuery({ searchPostV1 } as never, {
            id: 'pol-1',
            name: 'P',
        })
        expect(ids).toEqual([])
        expect(searchPostV1).not.toHaveBeenCalled()
    })
})
