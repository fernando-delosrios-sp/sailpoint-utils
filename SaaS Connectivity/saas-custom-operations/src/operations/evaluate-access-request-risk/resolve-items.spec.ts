import { describe, expect, it, vi } from 'vitest'
import { resolveRequestedItems } from './resolve-items'

describe('resolveRequestedItems', () => {
    it('uses supplied requested items and ignores blank rows', async () => {
        const listAccessRequestStatusV1 = vi.fn()
        const items = await resolveRequestedItems({ listAccessRequestStatusV1 } as never, {
            accessRequestId: 'req-1',
            requestedItems: [
                { id: ' ap-1 ', type: 'access_profile', name: 'Engineering' },
                { id: '', type: 'ROLE' },
            ],
        })

        expect(items).toEqual([{ id: 'ap-1', type: 'ACCESS_PROFILE', name: 'Engineering' }])
        expect(listAccessRequestStatusV1).not.toHaveBeenCalled()
    })

    it('accepts the single object ISC sends for a one-item request', async () => {
        const listAccessRequestStatusV1 = vi.fn()
        const items = await resolveRequestedItems({ listAccessRequestStatusV1 } as never, {
            accessRequestId: 'req-1',
            requestedItems: { id: 'ap-1', type: 'ACCESS_PROFILE', name: 'Engineering', operation: 'Add' } as never,
        })

        expect(items).toEqual([{ id: 'ap-1', type: 'ACCESS_PROFILE', name: 'Engineering' }])
        expect(listAccessRequestStatusV1).not.toHaveBeenCalled()
    })

    it('parses requested items delivered as a JSON string', async () => {
        const listAccessRequestStatusV1 = vi.fn()
        const items = await resolveRequestedItems({ listAccessRequestStatusV1 } as never, {
            requestedItems: JSON.stringify([{ id: 'ent-1', type: 'ENTITLEMENT' }]),
        })

        expect(items).toEqual([{ id: 'ent-1', type: 'ENTITLEMENT' }])
    })

    it('rejects a requested items string that is not JSON', async () => {
        await expect(
            resolveRequestedItems({ listAccessRequestStatusV1: vi.fn() } as never, { requestedItems: 'ap-1' })
        ).rejects.toThrow(/not valid JSON/)
    })

    it('loads items from access request status when the trigger items are omitted', async () => {
        const listAccessRequestStatusV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    id: 'status-row',
                    accessRequestId: 'req-1',
                    requestedObject: { id: 'role-1', type: 'ROLE', name: 'Analyst' },
                },
            ],
        })

        const items = await resolveRequestedItems({ listAccessRequestStatusV1 } as never, {
            accessRequestId: 'req-1',
        })

        expect(listAccessRequestStatusV1).toHaveBeenCalledWith({
            filters: 'accessRequestId eq "req-1"',
        })
        expect(items).toEqual([{ id: 'role-1', type: 'ROLE', name: 'Analyst' }])
    })

    it('does not treat the access request id as an access item id', async () => {
        const listAccessRequestStatusV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'req-1', type: 'ROLE', accessRequestId: 'req-1' }],
        })

        await expect(
            resolveRequestedItems({ listAccessRequestStatusV1 } as never, { accessRequestId: 'req-1' })
        ).rejects.toThrow(/Pass requestedItems/)
    })

    it('requires requested items or an access request id', async () => {
        await expect(resolveRequestedItems({ listAccessRequestStatusV1: vi.fn() } as never, {})).rejects.toThrow(
            /requestedItems or accessRequestId/
        )
    })
})
