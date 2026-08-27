import { describe, expect, it, vi } from 'vitest'
import { resolveIdentityIdForAccessRequest } from './resolve-identity-for-access-request'

describe('isc/access-requests/resolve-identity-for-access-request', () => {
    it('resolveIdentityIdForAccessRequest returns requestedFor id for EXECUTING GRANT_ACCESS match', async () => {
        const listAccessRequestStatusV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    id: 'item-1',
                    accessRequestId: 'track-1',
                    requestType: 'GRANT_ACCESS',
                    state: 'EXECUTING',
                    requestedFor: { id: 'identity-1' },
                },
            ],
        })

        const identityId = await resolveIdentityIdForAccessRequest(
            { listAccessRequestStatusV1 } as never,
            'track-1'
        )

        expect(listAccessRequestStatusV1).toHaveBeenCalledWith({
            requestState: 'EXECUTING',
            filters: 'accessRequestId eq "track-1"',
        })
        expect(identityId).toBe('identity-1')
    })

    it('resolveIdentityIdForAccessRequest throws when no EXECUTING GRANT_ACCESS match', async () => {
        const listAccessRequestStatusV1 = vi.fn().mockResolvedValue({ data: [] })

        await expect(
            resolveIdentityIdForAccessRequest({ listAccessRequestStatusV1 } as never, 'missing')
        ).rejects.toThrow(/Could not resolve identity/)
    })
})
