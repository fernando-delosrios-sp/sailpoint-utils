import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { governanceGroupEmailsOperation } from './index'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const resolveGovernanceGroupEmails = vi.fn()
const resolveGovernanceGroupEmailsOffline = vi.fn()

vi.mock('../../isc/governance-groups', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/governance-groups')>()
    return {
        ...actual,
        resolveGovernanceGroupEmails: (...args: unknown[]) => resolveGovernanceGroupEmails(...args),
        resolveGovernanceGroupEmailsOffline: (...args: unknown[]) =>
            resolveGovernanceGroupEmailsOffline(...args),
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
        governanceGroups: {},
    })),
}))

describe('governanceGroupEmailsOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockClear()
        resolveGovernanceGroupEmails.mockReset()
        resolveGovernanceGroupEmailsOffline.mockReset()
        resolveGovernanceGroupEmails.mockResolvedValue(['a@example.com', 'b@example.com'])
        resolveGovernanceGroupEmailsOffline.mockReturnValue(['offline-a@example.com', 'offline-b@example.com'])
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
                        { name: 'governance-group-emails:emails', type: 'STRING', isMulti: true },
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

    it('persists emails array on happy path', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await governanceGroupEmailsOperation(
                { commandType: 'custom:governance-group-emails' } as never,
                {
                    requestId: 'req-gg-1',
                    groupName: 'Approvers',
                },
                res as never
            )
        })

        expect(resolveGovernanceGroupEmails).toHaveBeenCalledWith(expect.anything(), 'Approvers')
        expect(createAccountV1).toHaveBeenCalledWith(
            expect.objectContaining({
                accountAttributesCreate: expect.objectContaining({
                    attributes: expect.objectContaining({
                        id: 'req-gg-1',
                        'governance-group-emails:emails': ['a@example.com', 'b@example.com'],
                    }),
                }),
            })
        )
        expect(res.send).toHaveBeenCalledWith({ status: 'success' })
    })

    it('returns failed status when groupName is missing', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await governanceGroupEmailsOperation(
                { commandType: 'custom:governance-group-emails' } as never,
                { requestId: 'req-gg-missing' },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('Missing required input field: groupName'),
            })
        )
    })

    it('returns failed status when groupName is blank', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await governanceGroupEmailsOperation(
                { commandType: 'custom:governance-group-emails' } as never,
                { requestId: 'req-gg-blank', groupName: '   ' },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('Missing required input field: groupName'),
            })
        )
    })

    it('returns failed status when group is unknown on connected path', async () => {
        const { ConnectorError } = await import('@sailpoint/connector-sdk')
        resolveGovernanceGroupEmails.mockRejectedValue(
            new ConnectorError('Governance group not found: "Missing Group"')
        )
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await governanceGroupEmailsOperation(
                { commandType: 'custom:governance-group-emails' } as never,
                { requestId: 'req-gg-unknown', groupName: 'Missing Group' },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('Governance group not found: "Missing Group"'),
            })
        )
    })

    it('returns canned emails in offline mode without SDK calls', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'

        try {
            const res = { send: vi.fn() }
            await governanceGroupEmailsOperation(
                { commandType: 'custom:governance-group-emails' } as never,
                {
                    requestId: 'req-gg-offline',
                    groupName: 'Offline Approvers',
                },
                res as never
            )

            expect(resolveGovernanceGroupEmails).not.toHaveBeenCalled()
            expect(resolveGovernanceGroupEmailsOffline).toHaveBeenCalledWith('Offline Approvers')
            expect(res.send).toHaveBeenCalledWith({ status: 'success' })
        } finally {
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })
})
