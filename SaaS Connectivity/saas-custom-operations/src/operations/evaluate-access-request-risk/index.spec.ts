import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { evaluateAccessRequestRiskOperation } from './index'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

vi.mock('./catalog', () => ({
    createAccessRiskCatalog: () => ({
        getRole: vi.fn(),
        getAccessProfile: vi.fn(),
        getEntitlement: vi.fn(async () => ({ effectivePrivilege: 'HIGH', metadata: undefined })),
    }),
}))

const createAccountV1 = vi.fn()
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
        accessRequests: { listAccessRequestStatusV1: vi.fn() },
    })),
}))

describe('evaluateAccessRequestRiskOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockClear()
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
                        { name: 'evaluate-access-request-risk:tier', type: 'STRING', isMulti: false },
                        { name: 'evaluate-access-request-risk:situation-summary', type: 'STRING', isMulti: false },
                        { name: 'evaluate-access-request-risk:contributing-ids', type: 'STRING', isMulti: false },
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

    it('persists the highest tier and does not persist an approver', async () => {
        const res = { send: vi.fn() }
        await _withConfig(workflowConfig, async () => {
            await evaluateAccessRequestRiskOperation(
                { commandType: 'custom:evaluate-access-request-risk' } as never,
                {
                    requestId: 'req-risk-1',
                    requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
                },
                res as never
            )
        })

        const stored = persistedAccounts.get('req-risk-1')
        expect(stored?.['evaluate-access-request-risk:tier']).toBe('High')
        expect(stored?.status).toBe('success')
        expect(JSON.stringify(stored)).not.toContain('approver')
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                summary: { tier: 'High' },
            })
        )
    })

    it('returns failed and does not persist Low when input is missing', async () => {
        const res = { send: vi.fn() }
        await _withConfig(workflowConfig, async () => {
            await evaluateAccessRequestRiskOperation(
                { commandType: 'custom:evaluate-access-request-risk' } as never,
                { requestId: 'req-risk-missing' },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('requestedItems or accessRequestId'),
            })
        )
        expect(persistedAccounts.get('req-risk-missing')?.['evaluate-access-request-risk:tier']).toBeUndefined()
    })
})
