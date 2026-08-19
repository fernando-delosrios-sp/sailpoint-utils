import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '../auto-registry'
import { exampleOperation } from './index'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const createAccountV1 = vi.fn().mockResolvedValue({})
const deleteAccountAsyncV1 = vi.fn().mockResolvedValue({})
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
            deleteAccountAsyncV1: (...args: unknown[]) => deleteAccountAsyncV1(...args),
            listAccountsV1: (...args: unknown[]) => listAccountsV1(...args),
            putAccountV1: vi.fn(),
            getAccountV1: vi.fn().mockImplementation(async ({ id }) => {
                const nativeId = String(id).replace(/^isc-/, '')
                const attributes = persistedAccounts.get(nativeId)
                return attributes
                    ? { data: { id: `isc-${nativeId}`, sourceId: 'source-123', attributes } }
                    : { data: undefined }
            }),
        },
        tasks: {
            getTaskStatusV1: vi.fn().mockResolvedValue({
                data: { completed: '2026-08-11T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
            }),
        },
    })),
}))

describe('exampleOperation', () => {
    beforeEach(() => {
        createAccountV1.mockClear()
        deleteAccountAsyncV1.mockClear()
        persistedAccounts.clear()
        createAccountV1.mockImplementation(async ({ accountAttributesCreate }) => {
            const attributes = accountAttributesCreate.attributes as Record<string, unknown>
            persistedAccounts.set(String(attributes.id), attributes)
            return { data: { id: 'task-create-1' } }
        })
        deleteAccountAsyncV1.mockImplementation(async ({ id }) => {
            const nativeId = String(id).replace(/^isc-/, '')
            persistedAccounts.delete(nativeId)
            return {}
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
                        { name: 'summary', type: 'STRING', isMulti: false },
                        { name: 'step', type: 'STRING', isMulti: false },
                    ],
                },
            ],
        })
        listAccountsV1.mockImplementation(async ({ filters }) => {
            const filterText = String(filters ?? '')
            if (
                filterText.includes('sourceId eq') &&
                !filterText.includes('nativeIdentity eq') &&
                !filterText.includes('name eq') &&
                !filterText.includes('id eq')
            ) {
                return {
                    data: [...persistedAccounts.entries()].map(([id, attributes]) => ({
                        id: `isc-${id}`,
                        sourceId: 'source-123',
                        attributes,
                    })),
                }
            }

            const match = /(?:nativeIdentity|id|name) eq "([^"]+)"/.exec(filterText)
            const id = match?.[1]
            if (!id || !persistedAccounts.has(id)) {
                return { data: [] }
            }

            return { data: [{ id: `isc-${id}`, sourceId: 'source-123', attributes: persistedAccounts.get(id) }] }
        })
    })

    it('invokes with workflow-shaped payload, persists parent and child identities, and sends success', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await exampleOperation(
                { commandType: 'custom:example' } as any,
                {
                    requestId: 'req-888',
                    message: 'Hello, world!',
                },
                res as any
            )
        })

        expect(resolveSourceByName).toHaveBeenCalledWith(
            expect.anything(),
            'SaaS Custom Operations',
            'test-token',
            expect.arrayContaining([
                expect.objectContaining({ name: 'summary' }),
                expect.objectContaining({ name: 'step' }),
            ])
        )
        expect(createAccountV1).toHaveBeenCalledTimes(2)
        expect(createAccountV1).toHaveBeenCalledWith(
            expect.objectContaining({
                accountAttributesCreate: expect.objectContaining({
                    attributes: expect.objectContaining({
                        id: 'req-888:detail',
                        summary: 'Hello, world!',
                    }),
                }),
            })
        )
        expect(createAccountV1).toHaveBeenCalledWith(
            expect.objectContaining({
                accountAttributesCreate: expect.objectContaining({
                    attributes: expect.objectContaining({
                        id: 'req-888',
                        summary: 'Hello, world!',
                        step: '1',
                    }),
                }),
            })
        )
        expect(res.send).toHaveBeenCalledWith({ status: 'success' })
    })
})
