import { beforeEach, describe, expect, it, vi } from 'vitest'

const mockBundledReadConfig = vi.fn()
const mockExternalReadConfig = vi.fn()

vi.mock('@sailpoint/connector-sdk', () => ({
    readConfig: (...args: unknown[]) => mockBundledReadConfig(...args),
}))

vi.mock('module', () => ({
    createRequire: () => (moduleId: string) => {
        if (moduleId === '@sailpoint/connector-sdk') {
            return { readConfig: mockExternalReadConfig }
        }
        throw new Error(`unexpected module: ${moduleId}`)
    },
}))

describe('readInvokeConfig', () => {
    beforeEach(() => {
        vi.resetModules()
        mockBundledReadConfig.mockReset()
        mockExternalReadConfig.mockReset()
    })

    it('returns undefined when no config sources are available', async () => {
        mockExternalReadConfig.mockRejectedValue(new Error('no spcx store'))
        mockBundledReadConfig.mockRejectedValue(new Error('missing CONNECTOR_CONFIG'))

        const { readInvokeConfig } = await import('./invoke-config')
        await expect(readInvokeConfig()).resolves.toBeUndefined()
    })

    it('prefers spcx external readConfig over bundled readConfig', async () => {
        mockExternalReadConfig.mockResolvedValue({
            apiUrl: 'https://tenant.api.identitynow.com',
            token: 'external-token',
            sourceName: 'SaaS Custom Operations',
        })
        mockBundledReadConfig.mockResolvedValue({
            apiUrl: 'https://bundled.example.com',
            token: 'bundled-token',
            sourceName: 'Bundled',
        })

        const { readInvokeConfig } = await import('./invoke-config')
        const config = await readInvokeConfig()

        expect(config).toEqual({
            apiUrl: 'https://tenant.api.identitynow.com',
            token: 'external-token',
            sourceName: 'SaaS Custom Operations',
        })
        expect(mockBundledReadConfig).not.toHaveBeenCalled()
    })

    it('falls back to bundled CONNECTOR_CONFIG when external config is absent', async () => {
        mockExternalReadConfig.mockResolvedValue({})
        mockBundledReadConfig.mockResolvedValue({
            apiUrl: 'https://prod.api.identitynow.com',
            token: 'prod-token',
            sourceName: 'Production Source',
        })

        const { readInvokeConfig } = await import('./invoke-config')
        const config = await readInvokeConfig()

        expect(config).toEqual({
            apiUrl: 'https://prod.api.identitynow.com',
            token: 'prod-token',
            sourceName: 'Production Source',
        })
    })
})
