import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '../auto-registry'
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

const mockViolation = {
    id: 'vio-1',
    owner: { id: 'owner-default', name: 'Owner Default' },
    identity: { id: 'ident-1', name: 'Alice Example' },
    policy: { id: 'pol-1', name: 'AP vs AP' },
    leftSide: { entitlements: [{ id: 'ent-a', name: 'Entitlement A' }] },
    rightSide: { entitlements: [{ id: 'ent-b', name: 'Entitlement B' }] },
}

const persistedAccounts = new Map<string, Record<string, unknown>>()

const createAccountV1 = vi.fn().mockImplementation(async ({ accountAttributesCreate }) => {
    const attributes = accountAttributesCreate.attributes as Record<string, unknown>
    persistedAccounts.set(String(attributes.id), attributes)
    return {}
})

const putAccountV1 = vi.fn().mockImplementation(async ({ accountAttributes }) => {
    const attributes = accountAttributes.attributes as Record<string, unknown>
    persistedAccounts.set(String(attributes.id), attributes)
    return {}
})

const listAccountsV1 = vi.fn().mockImplementation(async ({ filters }) => {
    const match = /nativeIdentity eq "([^"]+)"/.exec(filters ?? '')
    const id = match?.[1]
    if (!id || !persistedAccounts.has(id)) {
        return { data: [] }
    }
    return { data: [{ id: `isc-${id}`, attributes: persistedAccounts.get(id) }] }
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
                { name: 'formUrl', type: 'STRING', isMulti: false },
                { name: 'situationSummary', type: 'STRING', isMulti: false },
            ],
        },
    ],
})

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
            updateSourceSchemaV1: vi.fn(),
        },
        accounts: {
            createAccountV1: (...args: unknown[]) => createAccountV1(...args),
            putAccountV1: (...args: unknown[]) => putAccountV1(...args),
            listAccountsV1: (...args: unknown[]) => listAccountsV1(...args),
        },
        forms: {},
        identityHistory: {},
        accessProfiles: {},
        roles: {},
    })),
}))

vi.mock('../../isc/isc-client', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/isc-client')>()
    return {
        ...actual,
        getViolationV1: (...args: unknown[]) => getViolationV1(...args),
        listControlsV1: (...args: unknown[]) => listControlsV1(...args),
    }
})

vi.mock('../../isc/identity-access-client', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/identity-access-client')>()
    return {
        ...actual,
        fetchIdentityAccessItemsFromSdk: (...args: unknown[]) => fetchIdentityAccessItemsFromSdk(...args),
        fetchIdentityAccessItemsOffline: (...args: unknown[]) => fetchIdentityAccessItemsOffline(...args),
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
        getViolationV1.mockResolvedValue(mockViolation)
        listControlsV1.mockResolvedValue([{ id: 'ctrl-1', name: 'Control 1' }])
        fetchIdentityAccessItemsFromSdk.mockResolvedValue([])
        fetchIdentityAccessItemsOffline.mockResolvedValue([])
        ensureSodFormDefinition.mockResolvedValue('def-1')
        createSodRemediationInstance.mockResolvedValue('https://tenant.identitynow.com/form/instance-1')
    })

    it('returns formUrl and situationSummary on happy path', async () => {
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
                    controlOptions: [{ label: 'Control 1', value: 'ctrl-1', sublabel: undefined }],
                }),
            })
        )
        expect(createAccountV1).toHaveBeenCalledWith(
            expect.objectContaining({
                accountAttributesCreate: expect.objectContaining({
                    attributes: expect.objectContaining({
                        formUrl: 'https://tenant.identitynow.com/form/instance-1',
                        situationSummary: expect.stringContaining('Alice Example'),
                    }),
                }),
            })
        )
        expect(res.send).toHaveBeenCalledWith({ status: 'success' })
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
                        situationSummary: expect.stringContaining('No compensating controls'),
                    }),
                }),
            })
        )
    })
})

