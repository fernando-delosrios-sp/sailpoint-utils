import { describe, expect, it, vi } from 'vitest'
import { resolveIdentityEmail } from './resolve-identity-email'

describe('resolveIdentityEmail', () => {
    it('returns the email from the first matching public identity', async () => {
        const fetchFn = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => [{ id: 'owner-1', email: 'owner-1@example.com' }],
        })

        await expect(
            resolveIdentityEmail(
                {
                    apiUrl: 'https://tenant.api.identitynow.com',
                    token: 'token',
                    fetchFn,
                },
                'owner-1'
            )
        ).resolves.toBe('owner-1@example.com')

        expect(fetchFn).toHaveBeenCalledWith(
            'https://tenant.api.identitynow.com/public-identities/v1?filters=id eq "owner-1"',
            expect.objectContaining({ method: 'GET' })
        )
    })

    it('returns empty string when no identity matches', async () => {
        const fetchFn = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => [],
        })

        await expect(
            resolveIdentityEmail(
                {
                    apiUrl: 'https://tenant.api.identitynow.com',
                    token: 'token',
                    fetchFn,
                },
                'missing-owner'
            )
        ).resolves.toBe('')
    })
})
