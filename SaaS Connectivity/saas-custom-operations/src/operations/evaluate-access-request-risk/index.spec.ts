import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { evaluateAccessRequestRiskOperation } from './index'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const getEntitlement = vi.fn()

vi.mock('./catalog', () => ({
    createAccessRiskCatalog: () => ({
        getRole: vi.fn(),
        getAccessProfile: vi.fn(),
        getEntitlement: (...args: unknown[]) => getEntitlement(...args),
    }),
}))

const createAccountV1 = vi.fn()
const listAccountsV1 = vi.fn()
const deleteAccountAsyncV1 = vi.fn()
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
            deleteAccountAsyncV1: (...args: unknown[]) => deleteAccountAsyncV1(...args),
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

/** Native identities the operation asked ISC about, extracted from Get Accounts filters. */
function lookedUpIdentities(): string[] {
    return listAccountsV1.mock.calls
        .map(([args]) => /(?:nativeIdentity|id|name) eq "([^"]+)"/.exec(String(args?.filters ?? ''))?.[1])
        .filter((identity): identity is string => Boolean(identity))
}

async function invokeRisk(
    input: Record<string, unknown>
): Promise<{ send: ReturnType<typeof vi.fn> }> {
    const res = { send: vi.fn() }
    await _withConfig(workflowConfig, async () => {
        await evaluateAccessRequestRiskOperation(
            { commandType: 'custom:evaluate-access-request-risk' } as never,
            input,
            res as never
        )
    })
    return res
}

describe('evaluateAccessRequestRiskOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockClear()
        listAccountsV1.mockClear()
        deleteAccountAsyncV1.mockClear()
        getEntitlement.mockReset()
        getEntitlement.mockResolvedValue({ effectivePrivilege: 'HIGH', metadata: undefined })
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

    it('successful evaluation persists on the prefixed identity and not on the bare request id', async () => {
        const res = await invokeRisk({
            requestId: 'req-abc:dynamic',
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
        })

        const stored = persistedAccounts.get('evaluate-access-request-risk:req-abc:dynamic')
        expect(stored?.['evaluate-access-request-risk:tier']).toBe('High')
        expect(stored?.status).toBe('success')
        expect(persistedAccounts.has('req-abc:dynamic')).toBe(false)
        expect(JSON.stringify(stored)).not.toContain('approver')
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                summary: { tier: 'High' },
            })
        )
    })

    it('persisted attribute keys are unchanged by the prefix', async () => {
        getEntitlement.mockResolvedValue({ effectivePrivilege: 'MEDIUM', metadata: undefined })

        await invokeRisk({
            requestId: 'req-abc:dynamic',
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
        })

        const stored = persistedAccounts.get('evaluate-access-request-risk:req-abc:dynamic')
        expect(stored?.['evaluate-access-request-risk:tier']).toBe('Medium')
        expect(stored).toHaveProperty('evaluate-access-request-risk:situation-summary')
        expect(stored).toHaveProperty('evaluate-access-request-risk:contributing-ids')
    })

    it('already-prefixed request id is not prefixed twice', async () => {
        await invokeRisk({
            requestId: 'evaluate-access-request-risk:req-abc:dynamic',
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
        })

        expect([...persistedAccounts.keys()]).toEqual(['evaluate-access-request-risk:req-abc:dynamic'])
    })

    it('request id without a wrapper discriminator still gets the prefix', async () => {
        await invokeRisk({
            requestId: 'manual-001',
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
        })

        expect([...persistedAccounts.keys()]).toEqual(['evaluate-access-request-risk:manual-001'])
    })

    it('handler lookup failure writes a failed account on the prefixed identity', async () => {
        getEntitlement.mockRejectedValue(new Error('entitlement not found'))

        const res = await invokeRisk({
            requestId: 'req-abc:dynamic',
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
        })

        const failed = persistedAccounts.get('evaluate-access-request-risk:req-abc:dynamic')
        expect(failed?.status).toBe('failed')
        expect(String(failed?.details)).toContain('entitlement not found')
        expect(failed?.['evaluate-access-request-risk:tier']).toBeUndefined()
        expect(persistedAccounts.has('req-abc:dynamic')).toBe(false)
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({ status: 'failed', error: expect.stringContaining('entitlement not found') })
        )
    })

    it('missing input rejection writes a failed account on the prefixed identity', async () => {
        const res = await invokeRisk({ requestId: 'req-abc:dynamic' })

        const failed = persistedAccounts.get('evaluate-access-request-risk:req-abc:dynamic')
        expect(failed?.status).toBe('failed')
        expect(String(failed?.details)).toContain('requestedItems or accessRequestId')
        expect(failed?.['evaluate-access-request-risk:tier']).toBeUndefined()
        expect(persistedAccounts.has('req-abc:dynamic')).toBe(false)
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('requestedItems or accessRequestId'),
            })
        )
    })

    it('each wrapper discriminator yields a distinct prefixed identity for one access request', async () => {
        for (const discriminator of ['submitted', 'dynamic', 'dynamic-approval']) {
            await invokeRisk({
                requestId: `req-abc:${discriminator}`,
                requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
            })
        }

        expect([...persistedAccounts.keys()].sort()).toEqual([
            'evaluate-access-request-risk:req-abc:dynamic',
            'evaluate-access-request-risk:req-abc:dynamic-approval',
            'evaluate-access-request-risk:req-abc:submitted',
        ])
    })

    it('leaves a pre-rename bare identity account unread and unchanged', async () => {
        const legacyAccount = {
            id: 'req-abc:dynamic',
            status: 'success',
            'evaluate-access-request-risk:tier': 'Low',
        }
        persistedAccounts.set('req-abc:dynamic', legacyAccount)

        await invokeRisk({
            requestId: 'req-abc:dynamic',
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
        })

        expect(persistedAccounts.get('evaluate-access-request-risk:req-abc:dynamic')?.[
            'evaluate-access-request-risk:tier'
        ]).toBe('High')
        expect(persistedAccounts.get('req-abc:dynamic')).toEqual(legacyAccount)
        expect(lookedUpIdentities()).not.toContain('req-abc:dynamic')
        expect(deleteAccountAsyncV1).not.toHaveBeenCalled()
    })
})
