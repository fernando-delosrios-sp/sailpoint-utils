import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { clearOperationSchemaRegistry } from '../../framework'
import { sodRemediationOperation } from './index'

function createMockJwt(payload: Record<string, unknown>): string {
    const header = Buffer.from(JSON.stringify({ alg: 'none' })).toString('base64url')
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url')
    return `${header}.${body}.signature`
}

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: createMockJwt({ identity_id: 'token-owner-id', sub: 'other-sub' }),
    sourceName: 'SaaS Custom Operations',
}

const sodRemediationPersistAttributes = [
    { name: 'sod-remediation:form-url', type: 'STRING', isMulti: false },
    { name: 'sod-remediation:situation-header', type: 'STRING', isMulti: false },
    { name: 'sod-remediation:situation-summary', type: 'STRING', isMulti: false },
    { name: 'sod-remediation:owner-email', type: 'STRING', isMulti: false },
]

const mockViolation = {
    id: 'vio-1',
    owner: { id: 'owner-default', name: 'Owner Default' },
    identity: { id: 'ident-1', name: 'Alice Example' },
    policy: { id: 'pol-1', name: 'AP vs AP' },
    leftSide: { entitlements: [{ id: 'ent-a', name: 'Entitlement A' }] },
    rightSide: { entitlements: [{ id: 'ent-b', name: 'Entitlement B' }] },
}

const persistedAccounts = new Map<string, Record<string, unknown>>()

const putAccountV1 = vi.fn().mockResolvedValue({})

const createAccountV1 = vi.fn().mockImplementation(async ({ accountAttributesCreate }) => {
    const attributes = accountAttributesCreate.attributes as Record<string, unknown>
    persistedAccounts.set(String(attributes.id), attributes)
    return { data: { id: 'task-create-1' } }
})

const deleteAccountAsyncV1 = vi.fn().mockImplementation(async ({ id }) => {
    const nativeId = String(id).replace(/^isc-/, '')
    persistedAccounts.delete(nativeId)
    return {}
})

const listAccountsV1 = vi.fn().mockImplementation(async ({ filters }) => {
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
const resolveSourceByName = vi.fn().mockResolvedValue('source-123')
const getSourceSchemasV1 = vi.fn().mockResolvedValue({
    data: [
        {
            id: 'schema-1',
            name: 'account',
            attributes: [
                { name: 'id', type: 'STRING', isMulti: false },
                { name: 'status', type: 'STRING', isMulti: false },
                { name: 'date', type: 'STRING', isMulti: false },
                ...sodRemediationPersistAttributes,
            ],
        },
    ],
})
const updateSourceSchemaV1 = vi.fn().mockResolvedValue({})

const getViolationV1 = vi.fn()
const listControlsV1 = vi.fn()
const fetchIdentityAccessItemsFromSdk = vi.fn()
const fetchIdentityAccessItemsOffline = vi.fn()
const ensureSodFormDefinition = vi.fn()
const createSodRemediationInstance = vi.fn()

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
            updateSourceSchemaV1: (...args: unknown[]) => updateSourceSchemaV1(...args),
        },
        accounts: {
            createAccountV1: (...args: unknown[]) => createAccountV1(...args),
            deleteAccountAsyncV1: (...args: unknown[]) => deleteAccountAsyncV1(...args),
            listAccountsV1: (...args: unknown[]) => listAccountsV1(...args),
            putAccountV1: (...args: unknown[]) => putAccountV1(...args),
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
        forms: {},
        identityHistory: {},
        accessProfiles: {},
        roles: {},
    })),
}))

vi.mock('../../isc/violations', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/violations')>()
    return {
        ...actual,
        getViolationV1: (...args: unknown[]) => getViolationV1(...args),
    }
})

vi.mock('../../isc/controls', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/controls')>()
    return {
        ...actual,
        listControlsV1: (...args: unknown[]) => listControlsV1(...args),
    }
})

vi.mock('../../isc/identity-access', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/identity-access')>()
    return {
        ...actual,
        fetchIdentityAccessItemsFromSdk: (...args: unknown[]) => fetchIdentityAccessItemsFromSdk(...args),
        fetchIdentityAccessItemsOffline: (...args: unknown[]) => fetchIdentityAccessItemsOffline(...args),
    }
})

const fetchKeepRecommendations = vi.fn()
const listAssignedEntitlements = vi.fn()
const resolveIdentityEmail = vi.fn()

vi.mock('../../isc/recommendations', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/recommendations')>()
    return {
        ...actual,
        fetchKeepRecommendations: (...args: unknown[]) => fetchKeepRecommendations(...args),
        fetchKeepRecommendationsOffline: actual.fetchKeepRecommendationsOffline,
    }
})

vi.mock('../../isc/identity-history', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/identity-history')>()
    return {
        ...actual,
        listAssignedEntitlements: (...args: unknown[]) => listAssignedEntitlements(...args),
        listAssignedEntitlementsOffline: actual.listAssignedEntitlementsOffline,
    }
})

vi.mock('../../isc/public-identities', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/public-identities')>()
    return {
        ...actual,
        resolveIdentityEmail: (...args: unknown[]) => resolveIdentityEmail(...args),
    }
})

vi.mock('./form-service', async (importOriginal) => {
    const actual = await importOriginal<typeof import('./form-service')>()
    return {
        ...actual,
        ensureSodFormDefinition: (...args: unknown[]) => ensureSodFormDefinition(...args),
        createSodRemediationInstance: (...args: unknown[]) => createSodRemediationInstance(...args),
    }
})

describe('sodRemediationOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockClear()
        updateSourceSchemaV1.mockClear()
        getSourceSchemasV1.mockClear()
        getSourceSchemasV1.mockResolvedValue({
            data: [
                {
                    id: 'schema-1',
                    name: 'account',
                    attributes: [
                        { name: 'id', type: 'STRING', isMulti: false },
                        { name: 'status', type: 'STRING', isMulti: false },
                        { name: 'date', type: 'STRING', isMulti: false },
                        ...sodRemediationPersistAttributes,
                    ],
                },
            ],
        })
        getViolationV1.mockResolvedValue(mockViolation)
        listControlsV1.mockResolvedValue([{ id: 'ctrl-1', name: 'Control 1' }])
        fetchIdentityAccessItemsFromSdk.mockResolvedValue([])
        fetchIdentityAccessItemsOffline.mockResolvedValue([])
        fetchKeepRecommendations.mockResolvedValue(new Map())
        listAssignedEntitlements.mockResolvedValue([])
        resolveIdentityEmail.mockResolvedValue('owner-default@example.com')
        ensureSodFormDefinition.mockResolvedValue('def-1')
        createSodRemediationInstance.mockResolvedValue('https://tenant.identitynow.com/form/instance-1')
    })

    it('returns namespaced output fields on happy path', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await sodRemediationOperation(
                { commandType: 'custom:sod-remediation' } as never,
                {
                    requestId: 'req-sod-1',
                    violationId: 'vio-1',
                    formName: 'SOD Remediation',
                },
                res as never
            )
        })

        expect(getViolationV1).toHaveBeenCalled()
        expect(fetchIdentityAccessItemsFromSdk).toHaveBeenCalledWith(expect.anything(), 'ident-1')
        expect(ensureSodFormDefinition).toHaveBeenCalled()
        expect(createSodRemediationInstance).toHaveBeenCalledWith(
            expect.objectContaining({
                recipientId: 'owner-default',
                formInput: expect.objectContaining({
                    hasControls: true,
                    violationId: 'vio-1',
                    targetIdentityId: 'ident-1',
                    groupAAccessSearch: expect.any(String),
                    groupBAccessSearch: expect.any(String),
                    situationSummaryHtml: expect.not.stringContaining('Remediation form:'),
                    controlOptions: [{ label: 'Control 1', value: 'ctrl-1' }],
                }),
            })
        )
        expect(resolveIdentityEmail).toHaveBeenCalledWith(
            expect.objectContaining({ apiUrl: workflowConfig.apiUrl }),
            'owner-default'
        )
        expect(createAccountV1).toHaveBeenCalledWith(
            expect.objectContaining({
                accountAttributesCreate: expect.objectContaining({
                    attributes: expect.objectContaining({
                        'sod-remediation:form-url': 'https://tenant.identitynow.com/form/instance-1',
                        'sod-remediation:situation-header':
                            '⚠️ SOD Violation Remediation Required — Alice Example',
                        'sod-remediation:situation-summary': expect.stringMatching(/Alice Example/),
                        'sod-remediation:owner-email': 'owner-default@example.com',
                    }),
                }),
            })
        )
        const persistedSummary = createAccountV1.mock.calls[0][0].accountAttributesCreate.attributes[
            'sod-remediation:situation-summary'
        ] as string
        expect(persistedSummary.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(persistedSummary).not.toContain('<ul>')
        expect(persistedSummary).toMatch(/access paths?.*in conflict/)
        expect(persistedSummary).toContain(
            '<a href=https://tenant.identitynow.com/form/instance-1>Remediate here</a>'
        )
        expect(res.send).toHaveBeenCalledWith({ status: 'success' })
    })

    it('reconciles schema from operation sidecar without auto-registry lookup', async () => {
        clearOperationSchemaRegistry()
        getSourceSchemasV1.mockResolvedValue({
            data: [
                {
                    id: 'schema-1',
                    name: 'account',
                    identityAttribute: 'id',
                    displayAttribute: 'id',
                    nativeObjectType: 'User',
                    attributes: [
                        { name: 'id', type: 'STRING', isMulti: false },
                        { name: 'status', type: 'STRING', isMulti: false },
                        { name: 'date', type: 'STRING', isMulti: false },
                    ],
                },
            ],
        })

        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await sodRemediationOperation(
                { commandType: 'custom:sod-remediation' } as never,
                {
                    requestId: 'req-sod-schema',
                    violationId: 'vio-1',
                    formName: 'SOD Remediation',
                },
                res as never
            )
        })

        expect(updateSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                jsonPatchOperation: expect.arrayContaining([
                    expect.objectContaining({
                        op: 'replace',
                        path: '/attributes',
                        value: expect.arrayContaining([
                            expect.objectContaining({ name: 'sod-remediation:form-url', type: 'STRING' }),
                        ]),
                    }),
                ]),
            })
        )
    })

    it('uses owner input override for recipient', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await sodRemediationOperation(
                { commandType: 'custom:sod-remediation' } as never,
                {
                    requestId: 'req-sod-2',
                    violationId: 'vio-1',
                    formName: 'SOD Remediation',
                    owner: 'owner-override',
                },
                res as never
            )
        })

        expect(createSodRemediationInstance).toHaveBeenCalledWith(
            expect.objectContaining({ recipientId: 'owner-override' })
        )
        expect(resolveIdentityEmail).toHaveBeenCalledWith(expect.anything(), 'owner-override')
    })

    it('creates form definition from seed when missing', async () => {
        ensureSodFormDefinition.mockResolvedValue('def-created')

        const res = { send: vi.fn() }
        await _withConfig(workflowConfig, async () => {
            await sodRemediationOperation(
                { commandType: 'custom:sod-remediation' } as never,
                {
                    requestId: 'req-sod-3',
                    violationId: 'vio-1',
                    formName: 'New SOD Form',
                },
                res as never
            )
        })

        expect(ensureSodFormDefinition).toHaveBeenCalledWith(expect.anything(), 'New SOD Form', 'token-owner-id')
    })

    it('uses offline fallback owner for form definition create', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'

        try {
            const res = { send: vi.fn() }
            await sodRemediationOperation(
                { commandType: 'custom:sod-remediation' } as never,
                {
                    requestId: 'req-sod-offline',
                    violationId: 'vio-offline',
                    formName: 'SOD Remediation',
                },
                res as never
            )

            expect(getViolationV1).not.toHaveBeenCalled()
            expect(fetchIdentityAccessItemsOffline).toHaveBeenCalledWith('offline-identity')
            expect(ensureSodFormDefinition).toHaveBeenCalledWith(
                expect.anything(),
                'SOD Remediation',
                'offline-owner'
            )
            expect(createSodRemediationInstance).toHaveBeenCalledWith(
                expect.objectContaining({ recipientId: 'offline-owner' })
            )
            expect(resolveIdentityEmail).not.toHaveBeenCalled()
        } finally {
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })

    it('sets hasControls false and notes summary when zero controls', async () => {
        listControlsV1.mockResolvedValue([])
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await sodRemediationOperation(
                { commandType: 'custom:sod-remediation' } as never,
                {
                    requestId: 'req-sod-4',
                    violationId: 'vio-1',
                    formName: 'SOD Remediation',
                },
                res as never
            )
        })

        expect(createSodRemediationInstance).toHaveBeenCalledWith(
            expect.objectContaining({
                formInput: expect.objectContaining({ hasControls: false }),
            })
        )
        expect(createAccountV1).toHaveBeenCalledWith(
            expect.objectContaining({
                accountAttributesCreate: expect.objectContaining({
                        attributes: expect.objectContaining({
                            'sod-remediation:situation-summary': expect.stringMatching(/Alice Example/),
                        }),
                }),
            })
        )
        const zeroControlsSummary = createAccountV1.mock.calls[0][0].accountAttributesCreate.attributes[
            'sod-remediation:situation-summary'
        ] as string
        expect(zeroControlsSummary.length).toBeLessThanOrEqual(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(zeroControlsSummary).toMatch(/Alice Example/)
        expect(zeroControlsSummary).toContain(
            '<a href=https://tenant.identitynow.com/form/instance-1>Remediate here</a>'
        )
    })
})


