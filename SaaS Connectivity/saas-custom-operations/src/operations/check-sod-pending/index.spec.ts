import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { checkSodPendingOperation } from './index'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const mockGetPendingEntitlements = vi.fn()
const mockGetGrantedEntitlements = vi.fn()
const mockListEnforcedSodPolicies = vi.fn()
const mockCheckPoliciesAgainstEntitlements = vi.fn()

vi.mock('../../isc/access-requests/entitlement-aggregation', () => ({
    getPendingEntitlements: (...args: unknown[]) => mockGetPendingEntitlements(...args),
    getGrantedEntitlements: (...args: unknown[]) => mockGetGrantedEntitlements(...args),
}))

vi.mock('../../isc/sod-policies/list-enforced-policies', () => ({
    listEnforcedSodPolicies: (...args: unknown[]) => mockListEnforcedSodPolicies(...args),
}))

vi.mock('../../isc/sod-policies/check-policies-against-entitlements', () => ({
    checkPoliciesAgainstEntitlements: (...args: unknown[]) => mockCheckPoliciesAgainstEntitlements(...args),
}))

const createAccountV1 = vi.fn()
const resolveSourceByName = vi.fn()

vi.mock('../../framework/result-source', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../framework/result-source')>()
    return {
        ...actual,
        resolveSourceByName: (...args: unknown[]) => resolveSourceByName(...args),
    }
})

vi.mock('../../framework/sdk-factory', () => ({
    createSailPointClients: vi.fn(() => ({
        sodPolicies: {},
    })),
}))

describe('checkSodPendingOperation', () => {
    beforeEach(() => {
        vi.clearAllMocks()
        resolveSourceByName.mockResolvedValue('source-123')
        mockGetPendingEntitlements.mockResolvedValue([])
        mockGetGrantedEntitlements.mockResolvedValue([])
        mockListEnforcedSodPolicies.mockResolvedValue([])
        mockCheckPoliciesAgainstEntitlements.mockReturnValue([])
    })

    it('returns invoke response without persist', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await checkSodPendingOperation(
                { commandType: 'custom:check-sod-pending' } as never,
                { requestId: 'req-sod', identityId: 'identity-1' },
                res as never
            )
        })

        expect(createAccountV1).not.toHaveBeenCalled()
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                name: 'custom:check-sod-pending',
                status: 'success',
                responses: [],
                summary: {
                    identityId: 'identity-1',
                    hasViolations: false,
                    violatedPolicyNames: [],
                    counts: {
                        pendingEntitlements: 0,
                        grantedEntitlements: 0,
                        combinedTotal: 0,
                    },
                },
            })
        )
    })

    it('returns violated policy names when local matching finds violations', async () => {
        mockCheckPoliciesAgainstEntitlements.mockReturnValue([
            { policyId: 'pol-1', policyName: 'Policy A', matchedLeft: ['e1'], matchedRight: ['e2'] },
        ])

        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await checkSodPendingOperation(
                { commandType: 'custom:check-sod-pending' } as never,
                { requestId: 'req-sod-violation', identityId: 'identity-2' },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                summary: expect.objectContaining({
                    hasViolations: true,
                    violatedPolicyNames: ['Policy A'],
                }),
            })
        )
    })

    it('returns failed status when identityId is missing', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await checkSodPendingOperation(
                { commandType: 'custom:check-sod-pending' } as never,
                { requestId: 'req-sod-missing' },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('identityId'),
            })
        )
    })
})
