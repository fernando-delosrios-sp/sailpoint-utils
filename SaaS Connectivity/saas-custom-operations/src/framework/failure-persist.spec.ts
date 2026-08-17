import { describe, expect, it, vi } from 'vitest'
import { persistFailedResult } from './failure-persist'

describe('persistFailedResult', () => {
    it('skips persist when requestId is missing', async () => {
        const persist = vi.fn()
        await persistFailedResult(undefined, 'operation failed', { persist } as never)
        expect(persist).not.toHaveBeenCalled()
    })

    it('skips persist when context is missing', async () => {
        const persist = vi.fn()
        await persistFailedResult('req-001', 'operation failed', undefined)
        expect(persist).not.toHaveBeenCalled()
    })

    it('writes failed account with details using verify false', async () => {
        const persist = vi.fn().mockResolvedValue(undefined)
        await persistFailedResult('req-001', 'operation failed', { persist } as never)

        expect(persist).toHaveBeenCalledWith('req-001', undefined, 'failed', {
            verify: false,
            details: 'operation failed',
        })
    })

    it('logs warning and does not throw when persist rejects', async () => {
        const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const persist = vi.fn().mockRejectedValue(new Error('ISC unavailable'))

        await expect(
            persistFailedResult('req-001', 'operation failed', { persist } as never)
        ).resolves.toBeUndefined()

        expect(warnSpy).toHaveBeenCalledWith(
            expect.stringMatching(/failed to write failure account for req-001.*ISC unavailable/)
        )
        warnSpy.mockRestore()
    })
})
