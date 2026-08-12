import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { beginPayloadOutputCapture, endPayloadOutputCapture } from '../../framework/payload-persist-collector'
import '../auto-registry'
import { preventiveSodCheckOperation } from './index'
import {
    OFFLINE_EMPTY_IDENTITY_ID,
    OFFLINE_EXISTING_IDENTITY_ID,
    OFFLINE_IDENTITY_ID,
} from './offline-data'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const preventivePersistAttributes = [
    { name: 'preventive-sod-check:has-violation', type: 'BOOLEAN', isMulti: false },
    { name: 'preventive-sod-check:situation-summary', type: 'STRING', isMulti: false },
    { name: 'preventive-sod-check:violated-policy-names', type: 'STRING', isMulti: true },
]

const persistedAccounts = new Map<string, Record<string, unknown>>()

const createAccountV1 = vi.fn()
const deleteAccountAsyncV1 = vi.fn()
const listAccountsV1 = vi.fn()
const getSourceSchemasV1 = vi.fn()
const resolveSourceByName = vi.fn()

const listAccessRequestStatusV1 = vi.fn()
const searchPostV1 = vi.fn()
const startPredictSodViolationsV1 = vi.fn()
const getRoleEntitlementsV1 = vi.fn()
const getAccessProfileEntitlementsV1 = vi.fn()

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
        accessRequests: { listAccessRequestStatusV1: (...args: unknown[]) => listAccessRequestStatusV1(...args) },
        search: { searchPostV1: (...args: unknown[]) => searchPostV1(...args) },
        sodViolations: { startPredictSodViolationsV1: (...args: unknown[]) => startPredictSodViolationsV1(...args) },
        roles: { getRoleEntitlementsV1: (...args: unknown[]) => getRoleEntitlementsV1(...args) },
        accessProfiles: {
            getAccessProfileEntitlementsV1: (...args: unknown[]) => getAccessProfileEntitlementsV1(...args),
        },
        governanceGroups: {
            listWorkgroupsV1: vi.fn(),
            listWorkgroupMembersV1: vi.fn(),
        },
    })),
}))

describe('preventiveSodCheckOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockClear()
        deleteAccountAsyncV1.mockClear()
        listAccessRequestStatusV1.mockReset()
        searchPostV1.mockReset()
        startPredictSodViolationsV1.mockReset()
        getRoleEntitlementsV1.mockReset()
        getAccessProfileEntitlementsV1.mockReset()

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
                        ...preventivePersistAttributes,
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

        listAccessRequestStatusV1.mockResolvedValue({
            data: [
                {
                    id: 'item-1',
                    accessRequestId: 'track-1',
                    requestType: 'GRANT_ACCESS',
                    state: 'EXECUTING',
                    requestedFor: { id: 'identity-live-1' },
                },
            ],
        })
        searchPostV1.mockResolvedValue({
            data: [{ attributes: { accessItemId: 'role-1', accessItemType: 'Role', accessItemName: 'Analyst' } }],
        })
        getRoleEntitlementsV1.mockResolvedValue({ data: [{ id: 'ent-1' }] })
        startPredictSodViolationsV1.mockResolvedValue({
            data: {
                violationContexts: [{ policy: { name: 'Finance Control' } }, { policy: { name: 'Procurement Control' } }],
            },
        })

        vi.stubGlobal(
            'fetch',
            vi.fn().mockResolvedValue({
                ok: true,
                json: async () => [],
            })
        )
    })

    it('persists namespaced outputs on happy path (offline, identity mode)', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        beginPayloadOutputCapture()
        const res = { send: vi.fn() }

        try {
            await preventiveSodCheckOperation(
                { commandType: 'custom:preventive-sod-check' } as never,
                {
                    requestId: 'offline-preventive-001',
                    identityId: OFFLINE_IDENTITY_ID,
                },
                res as never
            )

            const inhibited = endPayloadOutputCapture()
            expect(inhibited).toHaveLength(1)
            expect(inhibited[0]?.attributes['preventive-sod-check:has-violation']).toBe(true)
            expect(inhibited[0]?.attributes['preventive-sod-check:situation-summary']).toBe(
                'SoD policy violations found: Finance Control, Procurement Control'
            )
            expect(inhibited[0]?.attributes['preventive-sod-check:violated-policy-names']).toEqual([
                'Finance Control',
                'Procurement Control',
            ])
            expect(res.send).toHaveBeenCalledWith({ status: 'success' })
        } finally {
            endPayloadOutputCapture()
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })

    it('returns No violations found when no executing grants and no existing violations (offline)', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        beginPayloadOutputCapture()
        const res = { send: vi.fn() }

        try {
            await preventiveSodCheckOperation(
                { commandType: 'custom:preventive-sod-check' } as never,
                {
                    requestId: 'offline-preventive-empty-001',
                    identityId: OFFLINE_EMPTY_IDENTITY_ID,
                },
                res as never
            )

            const inhibited = endPayloadOutputCapture()
            expect(inhibited[0]?.attributes['preventive-sod-check:has-violation']).toBe(false)
            expect(inhibited[0]?.attributes['preventive-sod-check:situation-summary']).toBe('No violations found')
            expect(inhibited[0]?.attributes['preventive-sod-check:violated-policy-names']).toEqual([])
        } finally {
            endPayloadOutputCapture()
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })

    it('includes existing violations in identity mode (offline)', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        beginPayloadOutputCapture()
        const res = { send: vi.fn() }

        try {
            await preventiveSodCheckOperation(
                { commandType: 'custom:preventive-sod-check' } as never,
                {
                    requestId: 'offline-preventive-existing-001',
                    identityId: OFFLINE_EXISTING_IDENTITY_ID,
                },
                res as never
            )

            const inhibited = endPayloadOutputCapture()
            expect(inhibited[0]?.attributes['preventive-sod-check:has-violation']).toBe(true)
            expect(inhibited[0]?.attributes['preventive-sod-check:violated-policy-names']).toEqual([
                'Existing Control',
                'Finance Control',
                'Procurement Control',
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

    it('request mode attributes delta policies when accessRequestId matches executing grant', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        beginPayloadOutputCapture()
        const res = { send: vi.fn() }

        try {
            await preventiveSodCheckOperation(
                { commandType: 'custom:preventive-sod-check' } as never,
                {
                    requestId: 'offline-preventive-attrib-001',
                    accessRequestId: 'offline-tracking-001',
                },
                res as never
            )

            const inhibited = endPayloadOutputCapture()
            expect(inhibited[0]?.attributes['preventive-sod-check:has-violation']).toBe(true)
            expect(inhibited[0]?.attributes['preventive-sod-check:situation-summary']).toBe(
                'Access request offline-tracking-001 would violate SoD policies if completed: Finance Control, Procurement Control'
            )
            expect(inhibited[0]?.attributes['preventive-sod-check:violated-policy-names']).toEqual([
                'Finance Control',
                'Procurement Control',
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

    it('returns failed status when accessRequestId cannot be resolved offline', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }

        try {
            await preventiveSodCheckOperation(
                { commandType: 'custom:preventive-sod-check' } as never,
                {
                    requestId: 'offline-preventive-no-match-001',
                    accessRequestId: 'req-123',
                },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'failed',
                    error: expect.stringContaining('Could not resolve identity for access request: req-123'),
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

    it('returns failed status when neither identityId nor accessRequestId is provided', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await preventiveSodCheckOperation(
                { commandType: 'custom:preventive-sod-check' } as never,
                { requestId: 'req-missing-input' },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('Missing required input: identityId or accessRequestId'),
            })
        )
    })

    it('does not persist an approved field', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        beginPayloadOutputCapture()
        const res = { send: vi.fn() }

        try {
            await preventiveSodCheckOperation(
                { commandType: 'custom:preventive-sod-check' } as never,
                {
                    requestId: 'offline-preventive-contract-001',
                    identityId: OFFLINE_IDENTITY_ID,
                },
                res as never
            )

            const inhibited = endPayloadOutputCapture()
            const attributes = inhibited[0]?.attributes ?? {}
            expect(attributes).not.toHaveProperty('approved')
            expect(Object.keys(attributes).sort()).toEqual([
                'date',
                'id',
                'preventive-sod-check:has-violation',
                'preventive-sod-check:situation-summary',
                'preventive-sod-check:violated-policy-names',
                'sourceId',
                'status',
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

    it('invokes connected path with SDK clients and persists violations', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await preventiveSodCheckOperation(
                { commandType: 'custom:preventive-sod-check' } as never,
                {
                    requestId: 'req-connected-001',
                    identityId: 'identity-live-1',
                },
                res as never
            )
        })

        expect(listAccessRequestStatusV1).toHaveBeenCalled()
        expect(startPredictSodViolationsV1).toHaveBeenCalled()
        const persisted = persistedAccounts.get('req-connected-001')
        expect(persisted?.['preventive-sod-check:has-violation']).toBe(true)
        expect(persisted?.['preventive-sod-check:violated-policy-names']).toEqual([
            'Finance Control',
            'Procurement Control',
        ])
    })
})
