import { describe, expect, it, vi } from 'vitest'
import { EXPERIMENTAL_HEADER } from '../http'
import { listControlsV1 } from './index'

describe('isc/controls', () => {
    it('listControlsV1 calls GET /controls/v1 with experimental header', async () => {
        const fetchFn = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => [{ id: 'ctrl-1', name: 'Control 1' }],
        })

        const controls = await listControlsV1({
            apiUrl: 'https://tenant.api.identitynow.com/',
            token: 'tok',
            fetchFn,
        })

        expect(fetchFn).toHaveBeenCalledWith(
            'https://tenant.api.identitynow.com/controls/v1',
            expect.objectContaining({
                headers: expect.objectContaining({
                    [EXPERIMENTAL_HEADER]: 'true',
                }),
            })
        )
        expect(controls).toHaveLength(1)
    })
})
