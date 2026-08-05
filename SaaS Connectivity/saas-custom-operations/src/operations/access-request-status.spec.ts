import { ConnectorError } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@sailpoint/connector-sdk', async () => {
    const actual = await vi.importActual<typeof import('@sailpoint/connector-sdk')>('@sailpoint/connector-sdk')
    return {
        ...actual,
        readConfig: vi.fn().mockResolvedValue({
            apiUrl: 'https://tenant.api.identitynow.com',
            token: 'token',
            sourceId: 'source-1',
        }),
    }
})

const mockPersist = vi.fn().mockResolvedValue(undefined)

vi.mock('../framework/request-context', async () => {
    const actual = await vi.importActual<typeof import('../framework/request-context')>('../framework/request-context')
    return {
        ...actual,
        createRequestContext: vi.fn((_input, res) => ({
            requestId: _input.requestId,
            sourceId: _input.sourceId,
            sdk: {} as never,
            persist: mockPersist,
            verifyPersisted: vi.fn().mockResolvedValue(undefined),
            res,
        })),
    }
})

import { createRequestContext } from '../framework/request-context'
import { accessRequestStatusOperation } from './access-request-status'
import { checkSodPendingOperation } from './check-sod-pending'
import { accessRequestThresholdOperation } from './access-request-threshold'
import { govgroupEmailsOperation } from './govgroup-emails'

vi.mock('../services/access-request-analytics', () => ({
    computeAccessRequestAnalytics: vi.fn(),
    fetchIdentityDisplayContext: vi.fn(),
}))

const mockGetRequestedItemOwnerId = vi.fn().mockResolvedValue('owner-123')
const mockResolveGroupEmails = vi.fn().mockResolvedValue('a@example.com, b@example.com')
const mockGetWorkgroupIdByName = vi.fn().mockResolvedValue('wg-1')

vi.mock('../services/access.service', () => ({
    AccessService: vi.fn().mockImplementation(() => ({
        fetchAccessRequestById: vi.fn().mockResolvedValue({
            id: 'item-1',
            type: 'ROLE',
            requestedFor: { id: 'identity-1' },
            accessRequestId: 'ar-threshold',
        }),
        buildPayload: vi.fn().mockReturnValue({ getAccessRequestStatus: {}, getXdrData: null }),
        getUnderlyingEntitlements: vi.fn().mockResolvedValue([]),
        getPendingEntitlements: vi.fn().mockResolvedValue([]),
        getGrantedEntitlements: vi.fn().mockResolvedValue([]),
        getRequestedItemOwnerId: mockGetRequestedItemOwnerId,
    })),
}))

vi.mock('../services/workgroup.service', () => ({
    WorkgroupService: vi.fn().mockImplementation(() => ({
        getWorkgroupIdByName: mockGetWorkgroupIdByName,
        resolveGroupEmails: mockResolveGroupEmails,
    })),
}))

vi.mock('../services/sod.service', () => ({
    SodService: vi.fn().mockImplementation(() => ({
        fetchSodPolicies: vi.fn().mockResolvedValue([]),
        checkPoliciesAgainstEntitlements: vi.fn().mockReturnValue([]),
    })),
}))

import { computeAccessRequestAnalytics, fetchIdentityDisplayContext } from '../services/access-request-analytics'

const mockedAnalytics = vi.mocked(computeAccessRequestAnalytics)
const mockedIdentityContext = vi.mocked(fetchIdentityDisplayContext)

describe('accessRequestStatusOperation', () => {
    beforeEach(() => {
        vi.clearAllMocks()
        mockPersist.mockClear()
        mockGetRequestedItemOwnerId.mockResolvedValue('owner-123')
        mockResolveGroupEmails.mockResolvedValue('a@example.com, b@example.com')
        mockedAnalytics.mockResolvedValue({
            iscRiskName: 'Low',
            xdrScore: '1.00%',
            sodPrediction: 'N/A',
            violatedPolicyNames: 'N/A',
            recommendationsDecision: 'YES',
            recommendationsInterpretations: 'ok',
            accessRequestStatus: {
                id: 'item-1',
                type: 'ROLE',
                requestedFor: { id: 'identity-1' },
                name: 'Test Role',
            },
            xdrData: null,
        })
        mockedIdentityContext.mockResolvedValue({
            displayName: 'Jane Doe',
            managerRefName: 'Manager Name',
        })
    })

    it('persists ets-comment profile output', async () => {
        const send = vi.fn()

        await accessRequestStatusOperation(
            { commandType: 'custom:access-request-status' } as never,
            {
                requestId: 'req-1',
                outputProfile: 'ets-comment',
                accessRequestId: 'ar-1',
            },
            { send } as never
        )

        expect(mockPersist).toHaveBeenCalledWith('req-1', [expect.stringContaining('Low Risk')])
        expect(send).toHaveBeenCalledWith(expect.objectContaining({ outputProfile: 'ets-comment' }))
    })

    it('persists approval-email profile output', async () => {
        const send = vi.fn()

        await accessRequestStatusOperation(
            { commandType: 'custom:access-request-status' } as never,
            {
                requestId: 'req-2',
                outputProfile: 'approval-email',
                accessRequestId: 'ar-2',
            },
            { send } as never
        )

        expect(mockPersist).toHaveBeenCalledWith(
            'req-2',
            expect.arrayContaining(['manager', expect.stringContaining('Jane Doe'), 'N/A', 'owner-123'])
        )
        expect(send).toHaveBeenCalledWith(expect.objectContaining({ emailRoute: 'manager' }))
    })

    it('throws when outputProfile is missing', async () => {
        await expect(
            accessRequestStatusOperation(
                { commandType: 'custom:access-request-status' } as never,
                { requestId: 'req-3', accessRequestId: 'ar-3' },
                { send: vi.fn() } as never
            )
        ).rejects.toBeInstanceOf(ConnectorError)
    })
})

describe('govgroupEmailsOperation', () => {
    it('persists comma-separated emails', async () => {
        const send = vi.fn()

        await govgroupEmailsOperation(
            { commandType: 'custom:govgroup-emails' } as never,
            { requestId: 'req-gov', groupName: 'SOD Governance Group' },
            { send } as never
        )

        expect(mockPersist).toHaveBeenCalledWith('req-gov', ['a@example.com, b@example.com'])
        expect(send).toHaveBeenCalledWith(expect.objectContaining({ emails: 'a@example.com, b@example.com' }))
    })
})

describe('deferred operations', () => {
    it('persists threshold result and returns invoke summary', async () => {
        const send = vi.fn()

        await accessRequestThresholdOperation(
            { commandType: 'custom:access-request-threshold' } as never,
            {
                requestId: 'req-threshold',
                accessRequestId: 'ar-threshold',
                sourceName: 'Active Directory',
                thresholdValue: 0,
            },
            { send } as never
        )

        expect(mockPersist).toHaveBeenCalledWith('req-threshold', [
            'false',
            '0',
            'Active Directory',
            '0',
            '0',
            '0',
            '0',
        ])
        expect(send).toHaveBeenCalledWith(expect.objectContaining({ thresholdHit: false }))
    })

    it('returns check-sod-pending response via ctx.res.send only', async () => {
        const send = vi.fn()

        await checkSodPendingOperation(
            { commandType: 'custom:check-sod-pending' } as never,
            { requestId: 'req-sod', identityId: 'identity-1' },
            { send } as never
        )

        expect(mockPersist).not.toHaveBeenCalled()
        expect(send).toHaveBeenCalledWith(
            expect.objectContaining({
                identityId: 'identity-1',
                hasViolations: false,
                violatedPolicyNames: 'N/A',
            })
        )
    })
})
