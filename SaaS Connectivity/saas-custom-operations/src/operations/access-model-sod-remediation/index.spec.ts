import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '../auto-registry'
import { beginPayloadOutputCapture, endPayloadOutputCapture } from '../../framework/payload-persist-collector'
import { accessModelSodRemediationOperation } from './index'
import { hasAssignedRemediationInstance } from './form-service'

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

vi.mock('./form-service', () => ({
    ensureAccessModelSodFormDefinition: vi.fn().mockResolvedValue('form-def-1'),
    hasAssignedRemediationInstance: vi.fn().mockResolvedValue(false),
    createAccessModelSodRemediationInstance: vi.fn().mockResolvedValue('https://tenant.example/form/1'),
}))

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
        forms: {},
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
        vi.mocked(hasAssignedRemediationInstance).mockResolvedValue(false)
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

    it('includes forms-skipped on res.send when duplicate form exists', async () => {
        vi.mocked(hasAssignedRemediationInstance).mockResolvedValue(true)
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
})
