import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import './auto-registry'
import { exampleOperation } from './example-operation'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const createAccountV1 = vi.fn().mockResolvedValue({})
const listAccountsV1 = vi.fn()
const getSourceSchemasV1 = vi.fn()
const resolveSourceByName = vi.fn()

vi.mock('../framework/source-provisioning', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../framework/source-provisioning')>()
    return {
        ...actual,
        resolveSourceByName: (...args: unknown[]) => resolveSourceByName(...args),
    }
})

vi.mock('../framework/sdk-factory', () => ({
    createSailPointClients: vi.fn(() => ({
        sources: {
            getSourceSchemasV1: (...args: unknown[]) => getSourceSchemasV1(...args),
            updateSourceSchemaV1: vi.fn(),
        },
        accounts: {
            createAccountV1: (...args: unknown[]) => createAccountV1(...args),
            listAccountsV1: (...args: unknown[]) => listAccountsV1(...args),
        },
    })),
}))

describe('exampleOperation', () => {
    beforeEach(() => {
        createAccountV1.mockClear()
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
            const match = /nativeIdentity eq "([^"]+)"/.exec(filters ?? '')
            const id = match?.[1]
            if (!id) {
                return { data: [] }
            }

            const attributes: Record<string, unknown> = {
                sourceId: 'source-123',
                id,
                date: '2026-08-06T00:00:00.000Z',
                status: 'success',
                summary: 'Hello, world!',
            }
            if (id === 'req-888') {
                attributes.step = '1'
            }

            return { data: [{ attributes }] }
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

        expect(resolveSourceByName).toHaveBeenCalledWith(expect.anything(), 'SaaS Custom Operations', 'test-token')
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

