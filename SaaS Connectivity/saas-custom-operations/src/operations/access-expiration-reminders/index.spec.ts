import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '../auto-registry'
import { beginPayloadOutputCapture, endPayloadOutputCapture } from '../../framework/payload-persist-collector'
import {
    buildOfflineRemoveDate,
    OFFLINE_REFERENCE_NOW,
    OFFLINE_SUNSET_IDENTITIES,
    searchIdentitiesWithSunsetAccessProfiles,
    searchIdentitiesWithSunsetAccessProfilesOffline,
} from '../../isc/identities'
import { resolveIdentityEmail } from '../../isc/public-identities'
import { resolveIdentityEmailOffline } from '../../isc/public-identities/offline-data'
import { createAccessExpirationRemindersInstance } from './form-service'
import { accessExpirationRemindersOperation } from './index'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const persistAttributes = [
    { name: 'access-expiration-reminders:identityId', type: 'STRING', isMulti: false },
    { name: 'access-expiration-reminders:managerId', type: 'STRING', isMulti: false },
    { name: 'access-expiration-reminders:accessProfileId', type: 'STRING', isMulti: false },
    { name: 'access-expiration-reminders:removeDate', type: 'STRING', isMulti: false },
    { name: 'access-expiration-reminders:daysRemaining', type: 'INT', isMulti: false },
    { name: 'access-expiration-reminders:form-url', type: 'STRING', isMulti: false },
    { name: 'access-expiration-reminders:form-email-header', type: 'STRING', isMulti: false },
    { name: 'access-expiration-reminders:form-email-body', type: 'STRING', isMulti: false },
    { name: 'access-expiration-reminders:form-email-recipients', type: 'STRING', isMulti: true },
]

function expectScanSummary(
    res: { send: ReturnType<typeof vi.fn> },
    summary: Record<string, unknown>
): void {
    expect(res.send).toHaveBeenCalledWith(
        expect.objectContaining({
            name: 'custom:access-expiration-reminders',
            status: 'success',
            summary: expect.objectContaining(summary),
        })
    )
}

const createAccountV1 = vi.fn().mockResolvedValue({})
const resolveSourceByName = vi.fn()
const getSourceSchemasV1 = vi.fn()
const persistedAccounts = new Map<string, Record<string, unknown>>()
const persistedIdentities: string[] = []

/** Mutable so the form-cap scenario can lower the default without affecting other tests. */
let mockedMaxFormsPerRun = 25

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
        ensureAccessExpirationRemindersFormDefinition: vi.fn().mockResolvedValue('form-def-1'),
        createAccessExpirationRemindersInstance: vi.fn().mockResolvedValue('https://tenant.example/form/1'),
    }
})

vi.mock('../../isc/public-identities', () => ({
    resolveIdentityEmail: vi.fn().mockResolvedValue('mgr-offline-1@example.com'),
}))

vi.mock('../../isc/public-identities/offline-data', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/public-identities/offline-data')>()
    return {
        ...actual,
        resolveIdentityEmailOffline: vi
            .fn()
            .mockImplementation((identityId: string) => actual.resolveIdentityEmailOffline(identityId)),
    }
})

vi.mock('./constants', async (importOriginal) => {
    const actual = await importOriginal<typeof import('./constants')>()
    return {
        ...actual,
        get MAX_FORMS_PER_RUN() {
            return mockedMaxFormsPerRun
        },
    }
})

vi.mock('../../isc/identities', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/identities')>()
    return {
        ...actual,
        searchIdentitiesWithSunsetAccessProfiles: vi
            .fn()
            .mockImplementation(async () => actual.searchIdentitiesWithSunsetAccessProfilesOffline()),
        searchIdentitiesWithSunsetAccessProfilesOffline: vi
            .fn()
            .mockImplementation(() => actual.searchIdentitiesWithSunsetAccessProfilesOffline()),
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
                data: { completed: '2026-08-19T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
            }),
        },
        forms: {},
        search: {},
    })),
}))

function cloneOfflineFixtures(now: Date = OFFLINE_REFERENCE_NOW) {
    const removeDate = matchingRemoveDate(now)
    return OFFLINE_SUNSET_IDENTITIES.map((identity) => ({
        ...identity,
        accessProfiles: identity.accessProfiles.map((ap) => ({ ...ap, removeDate })),
    }))
}

function matchingRemoveDate(now: Date = OFFLINE_REFERENCE_NOW): string {
    return buildOfflineRemoveDate(1, now)
}

async function invokeOffline(
    input: Record<string, unknown>,
    options: { capturePersist?: boolean } = {}
): Promise<{
    res: { send: ReturnType<typeof vi.fn> }
    inhibitedPersists: Array<{ identity: string; attributes: Record<string, unknown> }>
}> {
    const previousTestMode = process.env.SPCX_TEST_MODE
    process.env.SPCX_TEST_MODE = '1'
    const res = { send: vi.fn() }
    if (options.capturePersist) {
        beginPayloadOutputCapture()
    }

    try {
        await accessExpirationRemindersOperation(
            { commandType: 'custom:access-expiration-reminders' } as never,
            input,
            res as never
        )
        const inhibitedPersists = options.capturePersist ? endPayloadOutputCapture() : []
        return { res, inhibitedPersists }
    } finally {
        if (options.capturePersist) {
            endPayloadOutputCapture()
        }
        if (previousTestMode === undefined) {
            delete process.env.SPCX_TEST_MODE
        } else {
            process.env.SPCX_TEST_MODE = previousTestMode
        }
    }
}

async function invokeConnected(
    requestId: string,
    input: Record<string, unknown> = {}
): Promise<{ res: { send: ReturnType<typeof vi.fn> } }> {
    const res = { send: vi.fn() }
    await _withConfig(workflowConfig, async () => {
        await accessExpirationRemindersOperation(
            { commandType: 'custom:access-expiration-reminders' } as never,
            {
                requestId,
                formName: 'Access Expiration Reminders',
                ...input,
            },
            res as never
        )
    })
    return { res }
}

describe('accessExpirationRemindersOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        persistedIdentities.length = 0
        mockedMaxFormsPerRun = 25
        createAccountV1.mockClear()
        vi.mocked(createAccessExpirationRemindersInstance).mockClear()
        vi.mocked(createAccessExpirationRemindersInstance).mockResolvedValue('https://tenant.example/form/1')
        vi.mocked(resolveIdentityEmail).mockReset()
        vi.mocked(resolveIdentityEmail).mockResolvedValue('mgr-offline-1@example.com')
        vi.mocked(resolveIdentityEmailOffline).mockReset()
        vi.mocked(resolveIdentityEmailOffline).mockImplementation((identityId: string) =>
            identityId === 'mgr-offline-1' ? 'mgr-offline-1@example.com' : `${identityId}@offline.example.com`
        )
        vi.mocked(searchIdentitiesWithSunsetAccessProfiles).mockReset()
        vi.mocked(searchIdentitiesWithSunsetAccessProfiles).mockImplementation(async () => cloneOfflineFixtures())
        vi.mocked(searchIdentitiesWithSunsetAccessProfilesOffline).mockReset()
        vi.mocked(searchIdentitiesWithSunsetAccessProfilesOffline).mockImplementation(() => cloneOfflineFixtures())
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
    })

    it('Operation invoked with required formName: happy path summary and child persist, no bare requestId', async () => {
        const requestId = 'req-access-expiration-happy'
        const { res, inhibitedPersists } = await invokeOffline(
            {
                requestId,
                formName: 'Access Expiration Reminders',
                expirationDays: 1,
            },
            { capturePersist: true }
        )

        expectScanSummary(res, {
            'access-expiration-reminders:identities-scanned': 2,
            'access-expiration-reminders:expirations-matched': 2,
            'access-expiration-reminders:forms-created': 1,
            'access-expiration-reminders:forms-skipped-missing-manager-email': 1,
        })

        const childId = `${requestId}:identity-offline-1:ap-offline-1`
        expect(inhibitedPersists.map((record) => record.identity)).toEqual([childId])
        expect(inhibitedPersists.some((record) => record.identity === requestId)).toBe(false)

        const child = inhibitedPersists[0]?.attributes
        expect(child).toEqual(
            expect.objectContaining({
                'access-expiration-reminders:identityId': 'identity-offline-1',
                'access-expiration-reminders:managerId': 'mgr-offline-1',
                'access-expiration-reminders:accessProfileId': 'ap-offline-1',
                'access-expiration-reminders:removeDate': matchingRemoveDate(),
                'access-expiration-reminders:daysRemaining': 1,
                'access-expiration-reminders:form-url': 'https://tenant.example/form/1',
                'access-expiration-reminders:form-email-header': expect.any(String),
                'access-expiration-reminders:form-email-body': expect.any(String),
                'access-expiration-reminders:form-email-recipients': ['mgr-offline-1@example.com'],
            })
        )

        expect(vi.mocked(createAccessExpirationRemindersInstance)).toHaveBeenCalledWith(
            expect.objectContaining({
                expire: matchingRemoveDate(),
                formInput: expect.objectContaining({
                    responseAccountId: childId,
                    identityId: 'identity-offline-1',
                    accessProfileId: 'ap-offline-1',
                }),
            })
        )
    })

    it('Default expirationDays: omitted input defaults to 1', async () => {
        const { res, inhibitedPersists } = await invokeOffline(
            {
                requestId: 'req-access-expiration-default-days',
                formName: 'Access Expiration Reminders',
            },
            { capturePersist: true }
        )

        expectScanSummary(res, {
            'access-expiration-reminders:expirations-matched': 2,
            'access-expiration-reminders:forms-created': 1,
        })
        expect(inhibitedPersists[0]?.attributes).toEqual(
            expect.objectContaining({
                'access-expiration-reminders:daysRemaining': 1,
            })
        )
    })

    it('Missing formName fails with ConnectorError', async () => {
        const { res } = await invokeOffline({
            requestId: 'req-access-expiration-missing-form',
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('Missing required input field: formName'),
            })
        )
        expect(vi.mocked(createAccessExpirationRemindersInstance)).not.toHaveBeenCalled()
    })

    it('Existing notice account skips form and increments forms-skipped-existing', async () => {
        const requestId = 'req-access-expiration-idempotent'
        const childId = `${requestId}:identity-offline-1:ap-offline-1`
        persistedAccounts.set(childId, { id: childId })
        vi.mocked(searchIdentitiesWithSunsetAccessProfiles).mockImplementation(async () =>
            cloneOfflineFixtures(new Date())
        )

        const { res } = await invokeConnected(requestId, { expirationDays: 1 })

        expectScanSummary(res, {
            'access-expiration-reminders:expirations-matched': 2,
            'access-expiration-reminders:forms-created': 0,
            'access-expiration-reminders:forms-skipped-existing': 1,
            'access-expiration-reminders:forms-skipped-missing-manager-email': 1,
        })
        expect(vi.mocked(createAccessExpirationRemindersInstance)).not.toHaveBeenCalled()
        expect(persistedIdentities).not.toContain(childId)
        expect(persistedIdentities).not.toContain(requestId)
    })

    it('Missing manager skips form and increments missing-manager/email counter', async () => {
        const { res } = await invokeOffline({
            requestId: 'req-access-expiration-no-manager',
            formName: 'Access Expiration Reminders',
            expirationDays: 1,
        })

        expectScanSummary(res, {
            'access-expiration-reminders:forms-skipped-missing-manager-email': 1,
            'access-expiration-reminders:forms-created': 1,
        })
    })

    it('Manager without email skips form and increments missing-manager/email counter', async () => {
        vi.mocked(searchIdentitiesWithSunsetAccessProfilesOffline).mockReturnValue([
            {
                id: 'identity-empty-email',
                displayName: 'Empty Email User',
                managerId: 'mgr-empty-email',
                accessProfiles: [
                    {
                        id: 'ap-empty-email',
                        name: 'Empty Email AP',
                        removeDate: matchingRemoveDate(),
                        sourceName: 'SAP',
                    },
                ],
            },
        ])
        vi.mocked(resolveIdentityEmailOffline).mockReturnValue('')

        const { res, inhibitedPersists } = await invokeOffline(
            {
                requestId: 'req-access-expiration-empty-email',
                formName: 'Access Expiration Reminders',
                expirationDays: 1,
            },
            { capturePersist: true }
        )

        expectScanSummary(res, {
            'access-expiration-reminders:expirations-matched': 1,
            'access-expiration-reminders:forms-skipped-missing-manager-email': 1,
            'access-expiration-reminders:forms-created': 0,
        })
        expect(vi.mocked(createAccessExpirationRemindersInstance)).not.toHaveBeenCalled()
        expect(inhibitedPersists).toEqual([])
    })

    it('Multiple profiles yield multiple accounts', async () => {
        const removeDate = matchingRemoveDate()
        vi.mocked(searchIdentitiesWithSunsetAccessProfilesOffline).mockReturnValue([
            {
                id: 'id-a',
                displayName: 'Multi AP User',
                managerId: 'mgr-offline-1',
                accessProfiles: [
                    { id: 'ap-1', name: 'Profile One', removeDate, sourceName: 'SAP' },
                    { id: 'ap-2', name: 'Profile Two', removeDate, sourceName: 'SAP' },
                ],
            },
        ])

        const requestId = 'req-access-expiration-multi-ap'
        const { res, inhibitedPersists } = await invokeOffline(
            {
                requestId,
                formName: 'Access Expiration Reminders',
                expirationDays: 1,
            },
            { capturePersist: true }
        )

        expectScanSummary(res, {
            'access-expiration-reminders:expirations-matched': 2,
            'access-expiration-reminders:forms-created': 2,
        })
        expect(vi.mocked(createAccessExpirationRemindersInstance)).toHaveBeenCalledTimes(2)
        expect(inhibitedPersists.map((record) => record.identity).sort()).toEqual([
            `${requestId}:id-a:ap-1`,
            `${requestId}:id-a:ap-2`,
        ])
    })

    it('Cap reached: forms-overflow greater than zero', async () => {
        mockedMaxFormsPerRun = 1
        const removeDate = matchingRemoveDate()
        vi.mocked(searchIdentitiesWithSunsetAccessProfilesOffline).mockReturnValue([
            {
                id: 'id-cap-1',
                displayName: 'Cap User One',
                managerId: 'mgr-offline-1',
                accessProfiles: [{ id: 'ap-cap-1', name: 'Cap AP 1', removeDate, sourceName: 'SAP' }],
            },
            {
                id: 'id-cap-2',
                displayName: 'Cap User Two',
                managerId: 'mgr-offline-1',
                accessProfiles: [{ id: 'ap-cap-2', name: 'Cap AP 2', removeDate, sourceName: 'SAP' }],
            },
        ])

        const { res } = await invokeOffline({
            requestId: 'req-access-expiration-cap',
            formName: 'Access Expiration Reminders',
            expirationDays: 1,
        })

        expect(vi.mocked(createAccessExpirationRemindersInstance)).toHaveBeenCalledTimes(1)
        expectScanSummary(res, {
            'access-expiration-reminders:expirations-matched': 2,
            'access-expiration-reminders:forms-created': 1,
            'access-expiration-reminders:forms-overflow': 1,
        })
    })

    it('Zero matches summary only: no notice persist', async () => {
        const { res, inhibitedPersists } = await invokeOffline(
            {
                requestId: 'req-access-expiration-zero',
                formName: 'Access Expiration Reminders',
                expirationDays: 99,
            },
            { capturePersist: true }
        )

        expect(res.send).toHaveBeenCalledWith({
            name: 'custom:access-expiration-reminders',
            status: 'success',
            responses: [],
            summary: {
                'access-expiration-reminders:identities-scanned': 2,
                'access-expiration-reminders:expirations-matched': 0,
                'access-expiration-reminders:forms-created': 0,
            },
        })
        expect(inhibitedPersists).toEqual([])
        expect(vi.mocked(createAccessExpirationRemindersInstance)).not.toHaveBeenCalled()
    })

    it('Offline invoke returns summary', async () => {
        const { res } = await invokeOffline({
            requestId: 'req-access-expiration-offline',
            formName: 'Access Expiration Reminders',
            expirationDays: 1,
        })

        expectScanSummary(res, {
            'access-expiration-reminders:identities-scanned': expect.any(Number),
            'access-expiration-reminders:expirations-matched': expect.any(Number),
            'access-expiration-reminders:forms-created': expect.any(Number),
        })
    })

    it('Form inputs include correlation keys and expire equals removeDate', async () => {
        const requestId = 'req-access-expiration-form-input'
        await invokeOffline({
            requestId,
            formName: 'Access Expiration Reminders',
            expirationDays: 1,
        })

        expect(vi.mocked(createAccessExpirationRemindersInstance)).toHaveBeenCalledWith(
            expect.objectContaining({
                expire: matchingRemoveDate(),
                formInput: expect.objectContaining({
                    responseAccountId: `${requestId}:identity-offline-1:ap-offline-1`,
                    identityId: 'identity-offline-1',
                    accessProfileId: 'ap-offline-1',
                }),
            })
        )
    })
})
