import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { accessRequestStatusOperation } from './index'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const mockComputeAnalytics = vi.fn()
const mockFetchIdentityDisplayContext = vi.fn()
const mockGetRequestedItemOwnerId = vi.fn()
const mockResolveGovernanceGroupEmails = vi.fn()

vi.mock('./compute-analytics', () => ({
    computeAccessRequestAnalytics: (...args: unknown[]) => mockComputeAnalytics(...args),
}))

vi.mock('../../isc/identities/fetch-identity-display-context', () => ({
    fetchIdentityDisplayContext: (...args: unknown[]) => mockFetchIdentityDisplayContext(...args),
}))

vi.mock('../../isc/access-requests/requested-item', () => ({
    getRequestedItemOwnerId: (...args: unknown[]) => mockGetRequestedItemOwnerId(...args),
}))

vi.mock('../../isc/governance-groups', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/governance-groups')>()
    return {
        ...actual,
        resolveGovernanceGroupEmails: (...args: unknown[]) => mockResolveGovernanceGroupEmails(...args),
    }
})

const createAccountV1 = vi.fn().mockResolvedValue({})
const listAccountsV1 = vi.fn()
const getSourceSchemasV1 = vi.fn()
const resolveSourceByName = vi.fn()
const persistedAccounts = new Map<string, Record<string, unknown>>()

vi.mock('../../framework/result-source', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../framework/result-source')>()
    return {
        ...actual,
        resolveSourceByName: (...args: unknown[]) => resolveSourceByName(...args),
    }
})

vi.mock('../../framework/sdk-factory', () => ({
    createSailPointClients: vi.fn(() => ({
        sources: {
            getSourceSchemasV1: (...args: unknown[]) => getSourceSchemasV1(...args),
            updateSourceSchemaV1: vi.fn(),
        },
        accounts: {
            createAccountV1: (...args: unknown[]) => createAccountV1(...args),
            deleteAccountAsyncV1: vi.fn(),
            listAccountsV1: (...args: unknown[]) => listAccountsV1(...args),
            putAccountV1: vi.fn(),
            getAccountV1: vi.fn(),
        },
        tasks: {
            getTaskStatusV1: vi.fn().mockResolvedValue({
                data: { completed: '2026-08-11T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
            }),
        },
        identities: {},
        governanceGroups: {},
    })),
}))

describe('accessRequestStatusOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockClear()
        mockComputeAnalytics.mockReset()
        mockFetchIdentityDisplayContext.mockReset()
        mockGetRequestedItemOwnerId.mockReset()
        mockResolveGovernanceGroupEmails.mockReset()

        mockGetRequestedItemOwnerId.mockResolvedValue('owner-123')
        mockResolveGovernanceGroupEmails.mockResolvedValue(['a@example.com', 'b@example.com'])
        mockComputeAnalytics.mockResolvedValue({
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
        mockFetchIdentityDisplayContext.mockResolvedValue({
            displayName: 'Jane Doe',
            managerRefName: 'Manager Name',
        })

        createAccountV1.mockImplementation(async ({ accountAttributesCreate }) => {
            const attributes = accountAttributesCreate.attributes as Record<string, unknown>
            persistedAccounts.set(String(attributes.id), attributes)
            return { data: { id: 'task-create-1' } }
        })
        resolveSourceByName.mockResolvedValue('source-123')
        getSourceSchemasV1.mockResolvedValue({
            data: [
                {
                    id: 'schema-1',
                    name: 'account',
                    attributes: [
                        { name: 'id', type: 'STRING', isMulti: false },
                        { name: 'status', type: 'STRING', isMulti: false },
                        { name: 'date', type: 'STRING', isMulti: false },
                        { name: 'preApprovalComment', type: 'STRING', isMulti: false },
                        { name: 'emailRoute', type: 'STRING', isMulti: false },
                        { name: 'emailBodyHtml', type: 'STRING', isMulti: false },
                        { name: 'bccEmails', type: 'STRING', isMulti: true },
                        { name: 'accessOwnerId', type: 'STRING', isMulti: false },
                    ],
                },
            ],
        })
        listAccountsV1.mockImplementation(async ({ filters }) => {
            const filterText = String(filters ?? '')
            const match = /(?:nativeIdentity|id|name) eq "([^"]+)"/.exec(filterText)
            const id = match?.[1]
            if (!id || !persistedAccounts.has(id)) {
                return { data: [] }
            }
            return { data: [{ id: `isc-${id}`, sourceId: 'source-123', attributes: persistedAccounts.get(id) }] }
        })
    })

    it('persists ets-comment profile output', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessRequestStatusOperation(
                { commandType: 'custom:access-request-status' } as never,
                {
                    requestId: 'req-1',
                    outputProfile: 'ets-comment',
                    accessRequestId: 'ar-1',
                },
                res as never
            )
        })

        expect(persistedAccounts.get('req-1')).toMatchObject({
            preApprovalComment: expect.stringContaining('Low Risk'),
        })
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({ outputProfile: 'ets-comment', preApprovalComment: expect.stringContaining('Low Risk') })
        )
    })

    it('persists approval-email profile output', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessRequestStatusOperation(
                { commandType: 'custom:access-request-status' } as never,
                {
                    requestId: 'req-2',
                    outputProfile: 'approval-email',
                    accessRequestId: 'ar-2',
                },
                res as never
            )
        })

        expect(persistedAccounts.get('req-2')).toMatchObject({
            emailRoute: 'manager',
            emailBodyHtml: expect.stringContaining('Jane Doe'),
            bccEmails: [],
            accessOwnerId: 'owner-123',
        })
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({ emailRoute: 'manager', accessOwnerId: 'owner-123' })
        )
    })

    it('persists bccEmails array when approval route is manager-owner-bcc', async () => {
        mockComputeAnalytics.mockResolvedValue({
            iscRiskName: 'Critical',
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

        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessRequestStatusOperation(
                { commandType: 'custom:access-request-status' } as never,
                {
                    requestId: 'req-bcc',
                    outputProfile: 'approval-email',
                    accessRequestId: 'ar-bcc',
                    govGroupName: 'SOD Governance Group',
                },
                res as never
            )
        })

        expect(mockResolveGovernanceGroupEmails).toHaveBeenCalled()
        expect(persistedAccounts.get('req-bcc')).toMatchObject({
            emailRoute: 'manager-owner-bcc',
            emailBodyHtml: expect.stringContaining('Jane Doe'),
            bccEmails: ['a@example.com', 'b@example.com'],
            accessOwnerId: 'owner-123',
        })
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({ emailRoute: 'manager-owner-bcc' })
        )
    })

    it('returns failed status when outputProfile is missing', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessRequestStatusOperation(
                { commandType: 'custom:access-request-status' } as never,
                { requestId: 'req-3', accessRequestId: 'ar-3' },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('outputProfile'),
            })
        )
    })
})
