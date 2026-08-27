import { describe, expect, it, vi } from 'vitest'
import {
    filterGrantAccessRequests,
    listExecutingGrantAccessRequestsForIdentity,
    listExecutingAccessRequestsForIdentity,
} from './list-executing-grants'
import { listExecutingGrantAccessRequestsForIdentityOffline } from './offline-data'

describe('isc/access-requests', () => {
    it('listExecutingAccessRequestsForIdentity calls listAccessRequestStatusV1 with EXECUTING filter', async () => {
        const listAccessRequestStatusV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'req-1', requestType: 'GRANT_ACCESS', state: 'EXECUTING' }],
        })

        const items = await listExecutingAccessRequestsForIdentity(
            { listAccessRequestStatusV1 } as never,
            'identity-1'
        )

        expect(listAccessRequestStatusV1).toHaveBeenCalledWith({
            requestedFor: 'identity-1',
            requestState: 'EXECUTING',
        })
        expect(items).toHaveLength(1)
    })

    it('listExecutingGrantAccessRequestsForIdentity filters to GRANT_ACCESS only', async () => {
        const listAccessRequestStatusV1 = vi.fn().mockResolvedValue({
            data: [
                { id: 'grant-1', requestType: 'GRANT_ACCESS', state: 'EXECUTING' },
                { id: 'revoke-1', requestType: 'REVOKE_ACCESS', state: 'EXECUTING' },
            ],
        })

        const items = await listExecutingGrantAccessRequestsForIdentity(
            { listAccessRequestStatusV1 } as never,
            'identity-1'
        )

        expect(items).toEqual([{ id: 'grant-1', requestType: 'GRANT_ACCESS', state: 'EXECUTING' }])
    })

    it('filterGrantAccessRequests excludes non-grant operations', () => {
        const filtered = filterGrantAccessRequests([
            { requestType: 'GRANT_ACCESS' },
            { requestType: 'REVOKE_ACCESS' },
            { requestType: 'MODIFY_ACCESS' },
        ] as never)

        expect(filtered).toEqual([{ requestType: 'GRANT_ACCESS' }])
    })

    it('listExecutingGrantAccessRequestsForIdentityOffline returns canned executing grant', () => {
        const items = listExecutingGrantAccessRequestsForIdentityOffline('offline-identity')

        expect(items).toHaveLength(1)
        expect(items[0]?.requestType).toBe('GRANT_ACCESS')
        expect(items[0]?.state).toBe('EXECUTING')
    })
})
