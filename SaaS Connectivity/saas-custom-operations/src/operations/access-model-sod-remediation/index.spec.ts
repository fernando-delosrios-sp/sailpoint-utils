import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '../auto-registry'
import { beginPayloadOutputCapture, endPayloadOutputCapture } from '../../framework/payload-persist-collector'
import { accessModelSodRemediationOperation } from './index'
import { MAX_FORMS_PER_RUN } from './constants'
import { createAccessModelSodRemediationInstance } from './form-service'
import { listEnabledRoles } from '../../isc/roles'
import { expandAccessItemEntitlements } from './expand-access-item-entitlements'
import { expandAccessItemEntitlementsOffline } from './offline-data'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const persistAttributes = [
    { name: 'access-model-sod-remediation:access-items-scanned', type: 'INT', isMulti: false },
    { name: 'access-model-sod-remediation:violations-found', type: 'INT', isMulti: false },
    { name: 'access-model-sod-remediation:forms-skipped', type: 'INT', isMulti: false },
    { name: 'access-model-sod-remediation:form-url', type: 'STRING', isMulti: false },
    { name: 'access-model-sod-remediation:form-email-header', type: 'STRING', isMulti: false },
    { name: 'access-model-sod-remediation:form-email-body', type: 'STRING', isMulti: false },
    { name: 'access-model-sod-remediation:form-email-recipients', type: 'STRING', isMulti: true },
]

const createAccountV1 = vi.fn().mockResolvedValue({})
const resolveSourceByName = vi.fn()
const getSourceSchemasV1 = vi.fn()
const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({ data: [] })
const persistedAccounts = new Map<string, Record<string, unknown>>()
const persistedIdentities: string[] = []

vi.mock('../../framework/result-source', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../framework/result-source')>()
    return {
        ...actual,
        resolveSourceByName: (...args: unknown[]) => resolveSourceByName(...args),
    }
})

vi.mock('../../isc/token-identity', () => ({
    resolveTokenIdentity: vi.fn().mockResolvedValue('token-owner-id'),
}))

vi.mock('./form-service', async (importOriginal) => {
    const actual = await importOriginal<typeof import('./form-service')>()
    return {
        ...actual,
        ensureAccessModelSodFormDefinition: vi.fn().mockResolvedValue('form-def-1'),
        createAccessModelSodRemediationInstance: vi.fn().mockResolvedValue('https://tenant.example/form/1'),
    }
})

vi.mock('../../isc/roles', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/roles')>()
    return {
        ...actual,
        listEnabledRoles: vi.fn().mockImplementation(async () => actual.listEnabledRolesOffline()),
    }
})

vi.mock('../../isc/access-profiles', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/access-profiles')>()
    return {
        ...actual,
        listEnabledAccessProfiles: vi.fn().mockImplementation(async () => actual.listEnabledAccessProfilesOffline()),
    }
})

vi.mock('../../isc/sod-policies', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/sod-policies')>()
    return {
        ...actual,
        listSodPolicies: vi.fn().mockImplementation(async () => actual.listSodPoliciesOffline()),
    }
})

vi.mock('../../isc/public-identities', () => ({
    resolveIdentityEmail: vi.fn().mockResolvedValue('owner@example.com'),
}))

vi.mock('./constants', async (importOriginal) => {
    const actual = await importOriginal<typeof import('./constants')>()
    return {
        ...actual,
        MAX_FORMS_PER_RUN: 3,
    }
})

vi.mock('./expand-access-item-entitlements', async (importOriginal) => {
    const actual = await importOriginal<typeof import('./expand-access-item-entitlements')>()
    const offline = await import('./offline-data')
    return {
        ...actual,
        expandAccessItemEntitlements: vi
            .fn()
            .mockImplementation(async (_clients, item) => offline.expandAccessItemEntitlementsOffline(item)),
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
            listAccountsV1: vi.fn().mockImplementation(async ({ filters }) => {
                const match = /(?:nativeIdentity|id|name) eq "([^"]+)"/.exec(String(filters ?? ''))
                const id = match?.[1]
                if (!id || !persistedAccounts.has(id)) {
                    return { data: [] }
                }
                return {
                    data: [{ id: `isc-${id}`, sourceId: 'source-123', attributes: persistedAccounts.get(id) }],
                }
            }),
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
                data: { completed: '2026-08-18T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
            }),
        },
        roles: {},
        accessProfiles: {},
        forms: {
            searchFormInstancesByTenantV1: (...args: unknown[]) => searchFormInstancesByTenantV1(...args),
        },
        sodPolicies: {},
        search: {},
    })),
}))

describe('accessModelSodRemediationOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        persistedIdentities.length = 0
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
                        ...persistAttributes,
                    ],
                },
            ],
        })
        createAccountV1.mockImplementation(async ({ accountAttributesCreate }) => {
            const attributes = accountAttributesCreate.attributes as Record<string, unknown>
            const id = String(attributes.id)
            persistedAccounts.set(id, attributes)
            persistedIdentities.push(id)
            return { data: { id: 'task-create-1' } }
        })
        searchFormInstancesByTenantV1.mockResolvedValue({ data: [] })
    })

    it('returns scan summary on res.send and child persist only in offline mode', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }
        beginPayloadOutputCapture()

        try {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-offline',
                    formName: 'Access Model SOD Remediation',
                },
                res as never
            )

            const inhibitedPersists = endPayloadOutputCapture()

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'success',
                    'access-model-sod-remediation:access-items-scanned': 2,
                    'access-model-sod-remediation:violations-found': 1,
                })
            )
            expect(inhibitedPersists.map((record) => record.identity)).toEqual([
                'req-access-model-sod-offline:role-offline-1:policy-offline-1',
            ])
        } finally {
            endPayloadOutputCapture()
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })

    it('routes discover and policy step logs through ctx.log to logUrl', async () => {
        const fetchImpl = vi.fn().mockResolvedValue({ ok: true })
        vi.stubGlobal('fetch', fetchImpl)
        const res = { send: vi.fn() }

        try {
            await _withConfig(
                { ...workflowConfig, logUrl: 'https://logs.example.com/ingest' },
                async () => {
                    await accessModelSodRemediationOperation(
                        { commandType: 'custom:access-model-sod-remediation' } as never,
                        {
                            requestId: 'req-access-model-logurl',
                            formName: 'Access Model SOD Remediation',
                            searchIndices: ['roles'],
                        },
                        res as never
                    )
                }
            )

            await Promise.resolve()

            const postedMessages = fetchImpl.mock.calls.map((call) =>
                JSON.parse(String(call[1]?.body)).message
            )
            expect(postedMessages).toContain('discoverAccessItems')
            expect(postedMessages).toContain('access-model-sod-remediation start')
            expect(postedMessages).toContain('loadPolicies')
        } finally {
            vi.unstubAllGlobals()
        }
    })

    it('returns zero-violation scan summary without child persist in offline mode', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }

        try {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-zero',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['accessprofiles'],
                },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith({
                status: 'success',
                'access-model-sod-remediation:access-items-scanned': 1,
                'access-model-sod-remediation:violations-found': 0,
            })
        } finally {
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })

    it('includes forms-skipped on res.send when child persist account already exists', async () => {
        persistedAccounts.set('req-access-model-sod-skipped:role-offline-1:policy-offline-1', {
            id: 'req-access-model-sod-skipped:role-offline-1:policy-offline-1',
        })
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-skipped',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['roles'],
                },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation:access-items-scanned': 1,
                'access-model-sod-remediation:violations-found': 1,
                'access-model-sod-remediation:forms-skipped': 1,
                'access-model-sod-remediation:forms-skipped-instances': [
                    {
                        childIdentity: 'req-access-model-sod-skipped:role-offline-1:policy-offline-1',
                        accessItemId: 'role-offline-1',
                        accessItemType: 'ROLE',
                        accessItemName: 'Finance Role',
                        policyId: 'policy-offline-1',
                        policyName: 'AP/AR Separation',
                    },
                ],
            })
        )
        expect(vi.mocked(createAccessModelSodRemediationInstance)).not.toHaveBeenCalled()
        expect(persistedIdentities).not.toContain('req-access-model-sod-skipped:role-offline-1:policy-offline-1')
    })

    it('Different parent request does not skip child account from prior scan', async () => {
        persistedAccounts.set('req-access-model-sod-prior:role-offline-1:policy-offline-1', {
            id: 'req-access-model-sod-prior:role-offline-1:policy-offline-1',
        })
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-new',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['roles'],
                },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation:violations-found': 1,
            })
        )
        expect(res.send.mock.calls[0]?.[0]).not.toHaveProperty('access-model-sod-remediation:forms-skipped')
        expect(res.send.mock.calls[0]?.[0]).not.toHaveProperty(
            'access-model-sod-remediation:forms-skipped-instances'
        )
        expect(vi.mocked(createAccessModelSodRemediationInstance)).toHaveBeenCalled()
    })

    it('does not search form instances for idempotency', async () => {
        searchFormInstancesByTenantV1.mockClear()
        vi.mocked(listEnabledRoles).mockResolvedValueOnce([
            { id: 'role-offline-1', name: 'Finance Role', type: 'ROLE' },
            { id: 'role-offline-2', name: 'Ops Role', type: 'ROLE' },
        ])
        vi.mocked(expandAccessItemEntitlements)
            .mockImplementationOnce(async (_clients, item) =>
                expandAccessItemEntitlementsOffline({ ...item, id: 'role-offline-1' })
            )
            .mockImplementationOnce(async (_clients, item) =>
                expandAccessItemEntitlementsOffline({ ...item, id: 'role-offline-1' })
            )

        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-no-form-search',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['roles'],
                },
                res as never
            )
        })

        expect(searchFormInstancesByTenantV1).not.toHaveBeenCalled()
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation:access-items-scanned': 2,
                'access-model-sod-remediation:violations-found': 2,
            })
        )
    })

    it('does not persist rollup on requestId when connected', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-connected',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['roles'],
                },
                res as never
            )
        })

        expect(persistedIdentities).not.toContain('req-access-model-sod-connected')
        expect(persistedIdentities).toContain('req-access-model-sod-connected:role-offline-1:policy-offline-1')
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation:access-items-scanned': 1,
                'access-model-sod-remediation:violations-found': 1,
            })
        )
    })

    it('rejects invalid searchIndices', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }

        try {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-invalid',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['identities'] as never,
                },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'failed',
                    error: expect.stringMatching(/Invalid searchIndices/),
                })
            )
        } finally {
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })

    it('Launch failure increments launch counter only', async () => {
        vi.mocked(createAccessModelSodRemediationInstance).mockRejectedValueOnce(new Error('launch failed'))
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-launch-failed',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['roles'],
                },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation:violations-found': 1,
                'access-model-sod-remediation:forms-launch-failed': 1,
            })
        )
        expect(res.send).toHaveBeenCalledWith(
            expect.not.objectContaining({
                'access-model-sod-remediation:forms-persist-failed': expect.anything(),
            })
        )
        expect(persistedIdentities).not.toContain('req-access-model-sod-launch-failed:role-offline-1:policy-offline-1')
    })

    it('Scan stops creating forms at cap', async () => {
        const manyRoles = Array.from({ length: MAX_FORMS_PER_RUN + 2 }, (_, index) => ({
            id: `role-cap-${index}`,
            name: `Role ${index}`,
            type: 'ROLE' as const,
        }))
        vi.mocked(listEnabledRoles).mockResolvedValueOnce(manyRoles)
        vi.mocked(expandAccessItemEntitlements).mockImplementation(async () => ({
            entitlementIds: new Set(['ent-a', 'ent-c']),
            entitlements: [
                { id: 'ent-a', name: 'Accounts Receivable' },
                { id: 'ent-c', name: 'Accounts Payable' },
            ],
            nestedProfiles: [],
        }))
        vi.mocked(createAccessModelSodRemediationInstance).mockClear()

        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-form-cap',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['roles'],
                },
                res as never
            )
        })

        expect(vi.mocked(createAccessModelSodRemediationInstance)).toHaveBeenCalledTimes(MAX_FORMS_PER_RUN)
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation:access-items-scanned': MAX_FORMS_PER_RUN + 2,
                'access-model-sod-remediation:violations-found': MAX_FORMS_PER_RUN,
            })
        )
    })

    it('Child persist failure increments persist counter only', async () => {
        createAccountV1.mockRejectedValueOnce(new Error('persist failed'))
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-persist-failed',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['roles'],
                },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation:violations-found': 1,
                'access-model-sod-remediation:forms-persist-failed': 1,
            })
        )
        expect(res.send).toHaveBeenCalledWith(
            expect.not.objectContaining({
                'access-model-sod-remediation:forms-launch-failed': expect.anything(),
            })
        )
    })
})
