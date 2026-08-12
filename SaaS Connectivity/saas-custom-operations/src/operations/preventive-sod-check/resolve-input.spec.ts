import { describe, expect, it, vi } from 'vitest'
import { ConnectorError } from '@sailpoint/connector-sdk'
import { resolvePreventiveSodCheckInput } from './resolve-input'

describe('preventive-sod-check/resolve-input', () => {
    it('requires identityId or accessRequestId', async () => {
        await expect(resolvePreventiveSodCheckInput('req-1', {} as never, {}, true)).rejects.toThrow(ConnectorError)
    })

    it('resolves identity from accessRequestId in offline mode', async () => {
        const resolved = await resolvePreventiveSodCheckInput(
            'req-offline',
            {} as never,
            { accessRequestId: 'offline-tracking-001' },
            true
        )

        expect(resolved).toEqual({
            identityId: 'offline-preventive-identity',
            accessRequestId: 'offline-tracking-001',
        })
    })

    it('warns and ignores identityId when accessRequestId is provided', async () => {
        const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})

        try {
            const resolved = await resolvePreventiveSodCheckInput(
                'req-warn',
                {} as never,
                {
                    identityId: 'wrong-identity',
                    accessRequestId: 'offline-tracking-001',
                },
                true
            )

            expect(resolved.identityId).toBe('offline-preventive-identity')
            expect(warn).toHaveBeenCalledWith(
                '[req-warn] preventive-sod-check: identityId ignored when accessRequestId is provided'
            )
        } finally {
            warn.mockRestore()
        }
    })

    it('uses identityId in identity mode when accessRequestId is absent', async () => {
        const resolved = await resolvePreventiveSodCheckInput(
            'req-identity',
            {} as never,
            { identityId: 'identity-1' },
            true
        )

        expect(resolved).toEqual({ identityId: 'identity-1', accessRequestId: undefined })
    })
})
