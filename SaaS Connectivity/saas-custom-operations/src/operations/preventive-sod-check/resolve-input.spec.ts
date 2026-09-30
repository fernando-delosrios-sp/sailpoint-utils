import { describe, expect, it, vi } from 'vitest'
import { ConnectorError } from '@sailpoint/connector-sdk'
import { resolvePreventiveSodCheckInput } from './resolve-input'

const { mockLogger } = vi.hoisted(() => ({
    mockLogger: {
        info: vi.fn(),
        warn: vi.fn(),
        error: vi.fn(),
    },
}))

vi.mock('../../framework/logger', () => ({
    getActiveFrameworkLogger: vi.fn(() => mockLogger),
}))

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
            inflightOnly: false,
            requestedItems: [],
            waitForPersist: true,
        })
    })

    it('uses supplied identityId in request mode without resolving mutable request status', async () => {
        const listAccessRequestStatusV1 = vi.fn()

        const resolved = await resolvePreventiveSodCheckInput(
            'req-direct',
            { accessRequests: { listAccessRequestStatusV1 } } as never,
            {
                identityId: 'identity-1',
                accessRequestId: 'request-1',
            },
            false
        )

        expect(resolved.identityId).toBe('identity-1')
        expect(resolved.accessRequestId).toBe('request-1')
        expect(listAccessRequestStatusV1).not.toHaveBeenCalled()
    })

    it('uses identityId in identity mode when accessRequestId is absent', async () => {
        const resolved = await resolvePreventiveSodCheckInput(
            'req-identity',
            {} as never,
            { identityId: 'identity-1' },
            true
        )

        expect(resolved).toEqual({
            identityId: 'identity-1',
            accessRequestId: undefined,
            inflightOnly: false,
            requestedItems: [],
            waitForPersist: true,
        })
    })

    it('normalizes trigger requestedItems and non-blocking persistence input', async () => {
        const resolved = await resolvePreventiveSodCheckInput(
            'req-direct',
            {} as never,
            {
                identityId: 'identity-1',
                accessRequestId: 'request-1',
                requestedItems: {
                    id: ' ap-1 ',
                    type: 'access_profile',
                    name: 'Security',
                },
                waitForPersist: 'false',
            },
            false
        )

        expect(resolved.requestedItems).toEqual([
            { id: 'ap-1', type: 'ACCESS_PROFILE', name: 'Security' },
        ])
        expect(resolved.waitForPersist).toBe(false)
    })

    it('parses inflightOnly from boolean or string, defaulting to false', async () => {
        await expect(
            resolvePreventiveSodCheckInput('req-1', {} as never, { identityId: 'id-1', inflightOnly: true }, true)
        ).resolves.toMatchObject({ inflightOnly: true })
        await expect(
            resolvePreventiveSodCheckInput(
                'req-1',
                {} as never,
                { identityId: 'id-1', inflightOnly: 'true' },
                true
            )
        ).resolves.toMatchObject({ inflightOnly: true })
        await expect(
            resolvePreventiveSodCheckInput(
                'req-1',
                {} as never,
                { identityId: 'id-1', inflightOnly: 'false' },
                true
            )
        ).resolves.toMatchObject({ inflightOnly: false })
    })
})
