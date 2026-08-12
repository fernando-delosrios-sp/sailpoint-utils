import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { accessRequestThresholdOperation } from './index'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const mockFetchAccessRequestById = vi.fn()
const mockGetUnderlyingEntitlements = vi.fn()
const mockGetPendingEntitlements = vi.fn()
const mockGetGrantedEntitlements = vi.fn()

vi.mock('../../isc/access-requests/fetch-access-request-by-id', () => ({
    fetchAccessRequestById: (...args: unknown[]) => mockFetchAccessRequestById(...args),
}))

vi.mock('../../isc/access-requests/entitlement-aggregation', () => ({
    getUnderlyingEntitlements: (...args: unknown[]) => mockGetUnderlyingEntitlements(...args),
    getPendingEntitlements: (...args: unknown[]) => mockGetPendingEntitlements(...args),
    getGrantedEntitlements: (...args: unknown[]) => mockGetGrantedEntitlements(...args),
}))

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
        accessRequests: {},
    })),
}))

describe('accessRequestThresholdOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockClear()
        mockFetchAccessRequestById.mockReset()
        mockGetUnderlyingEntitlements.mockReset()
        mockGetPendingEntitlements.mockReset()
        mockGetGrantedEntitlements.mockReset()

        mockFetchAccessRequestById.mockResolvedValue({
            id: 'item-1',
            type: 'ROLE',
            requestedFor: { id: 'identity-1' },
            accessRequestId: 'ar-threshold',
        })
        mockGetUnderlyingEntitlements.mockResolvedValue([])
        mockGetPendingEntitlements.mockResolvedValue([])
        mockGetGrantedEntitlements.mockResolvedValue([])

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
                        { name: 'thresholdHit', type: 'BOOLEAN', isMulti: false },
                        { name: 'foundCount', type: 'INT', isMulti: false },
                        { name: 'sourceName', type: 'STRING', isMulti: false },
                        { name: 'thresholdValue', type: 'INT', isMulti: false },
                        { name: 'requestedCount', type: 'INT', isMulti: false },
                        { name: 'pendingCount', type: 'INT', isMulti: false },
                        { name: 'grantedCount', type: 'INT', isMulti: false },
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

    it('persists threshold result', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessRequestThresholdOperation(
                { commandType: 'custom:access-request-threshold' } as never,
                {
                    requestId: 'req-threshold',
                    accessRequestId: 'ar-threshold',
                    sourceName: 'Active Directory',
                    thresholdValue: 0,
                },
                res as never
            )
        })

        expect(persistedAccounts.get('req-threshold')).toMatchObject({
            thresholdHit: false,
            foundCount: 0,
            sourceName: 'Active Directory',
            thresholdValue: 0,
            requestedCount: 0,
            pendingCount: 0,
            grantedCount: 0,
        })
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                thresholdHit: false,
                details: expect.objectContaining({
                    identityId: 'identity-1',
                    source: 'Active Directory',
                    threshold: 0,
                    foundCount: 0,
                }),
            })
        )
    })
})
