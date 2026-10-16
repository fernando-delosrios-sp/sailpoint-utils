import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { beginPayloadOutputCapture, endPayloadOutputCapture } from '../../framework/payload-persist-collector'
import '../auto-registry'
import { evaluateAccessRequestOperation } from './index'
import { OFFLINE_IDENTITY_ID } from '../preventive-sod-check/offline-data'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const persistAttributes = [
    { name: 'evaluate-access-request-risk:tier', type: 'STRING', isMulti: false },
    { name: 'evaluate-access-request-risk:situation-summary', type: 'STRING', isMulti: false },
    { name: 'evaluate-access-request-risk:contributing-ids', type: 'STRING', isMulti: false },
    { name: 'preventive-sod-check:has-violation', type: 'BOOLEAN', isMulti: false },
    { name: 'preventive-sod-check:situation-summary', type: 'STRING', isMulti: false },
    { name: 'preventive-sod-check:violated-policy-names', type: 'STRING', isMulti: true },
]

const persistedAccounts = new Map<string, Record<string, unknown>>()

const createAccountV1 = vi.fn()
const listAccountsV1 = vi.fn()
const getSourceSchemasV1 = vi.fn()
const resolveSourceByName = vi.fn()
const getTaskStatusV1 = vi.fn()
const listAccessRequestStatusV1 = vi.fn()
const searchPostV1 = vi.fn()
const startPredictSodViolationsV1 = vi.fn()
const getRoleEntitlementsV1 = vi.fn()
const getEntitlementV1 = vi.fn()
const listSodPoliciesV1 = vi.fn()

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
            listAccountsV1: (...args: unknown[]) => listAccountsV1(...args),
            putAccountV1: vi.fn(),
            getAccountV1: vi.fn().mockImplementation(async ({ id }) => {
                const nativeId = String(id).replace(/^isc-/, '')
                const attributes = persistedAccounts.get(nativeId)
                return attributes
                    ? { data: { id: `isc-${nativeId}`, sourceId: 'source-123', attributes } }
                    : { data: undefined }
            }),
            deleteAccountAsyncV1: vi.fn(),
        },
        tasks: {
            getTaskStatusV1: (...args: unknown[]) => getTaskStatusV1(...args),
        },
        accessRequests: { listAccessRequestStatusV1: (...args: unknown[]) => listAccessRequestStatusV1(...args) },
        search: { searchPostV1: (...args: unknown[]) => searchPostV1(...args) },
        sodViolations: { startPredictSodViolationsV1: (...args: unknown[]) => startPredictSodViolationsV1(...args) },
        roles: { getRoleEntitlementsV1: (...args: unknown[]) => getRoleEntitlementsV1(...args), getRoleV1: vi.fn() },
        accessProfiles: { getAccessProfileEntitlementsV1: vi.fn(), getAccessProfileV1: vi.fn() },
        entitlements: { getEntitlementV1: (...args: unknown[]) => getEntitlementV1(...args) },
        sodPolicies: {
            getSodPolicyV1: vi.fn(),
            listSodPoliciesV1: (...args: unknown[]) => listSodPoliciesV1(...args),
        },
        governanceGroups: { listWorkgroupsV1: vi.fn(), listWorkgroupMembersV1: vi.fn() },
    })),
}))

async function invokeEvaluate(input: Record<string, unknown>): Promise<{ send: ReturnType<typeof vi.fn> }> {
    const res = { send: vi.fn() }
    await _withConfig(workflowConfig, async () => {
        await evaluateAccessRequestOperation(
            { commandType: 'custom:evaluate-access-request' } as never,
            input,
            res as never
        )
    })
    return res
}

describe('evaluateAccessRequestOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockClear()
        listAccountsV1.mockClear()
        getTaskStatusV1.mockReset()
        listAccessRequestStatusV1.mockReset()
        searchPostV1.mockReset()
        startPredictSodViolationsV1.mockReset()
        getRoleEntitlementsV1.mockReset()
        getEntitlementV1.mockReset()
        listSodPoliciesV1.mockReset()

        createAccountV1.mockImplementation(async ({ accountAttributesCreate }) => {
            const attributes = accountAttributesCreate.attributes as Record<string, unknown>
            persistedAccounts.set(String(attributes.id), attributes)
            return { data: { id: 'task-create-1' } }
        })
        getTaskStatusV1.mockResolvedValue({
            data: { completed: '2026-08-11T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
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
                        ...persistAttributes,
                    ],
                },
            ],
        })
        listAccountsV1.mockImplementation(async ({ filters }) => {
            const match = /(?:nativeIdentity|id|name) eq "([^"]+)"/.exec(String(filters ?? ''))
            const id = match?.[1]
            if (!id || !persistedAccounts.has(id)) {
                return { data: [] }
            }
            return { data: [{ id: `isc-${id}`, sourceId: 'source-123', attributes: persistedAccounts.get(id) }] }
        })
        listAccessRequestStatusV1.mockResolvedValue({ data: [] })
        searchPostV1.mockResolvedValue({ data: [] })
        startPredictSodViolationsV1.mockResolvedValue({ data: { violationContexts: [] } })
        getEntitlementV1.mockResolvedValue({
            data: { id: 'ent-1', privilegeLevel: { effective: 'HIGH' } },
        })
        listSodPoliciesV1.mockResolvedValue({ data: [] })
    })

    it('persists risk and SoD attributes once when evaluateSod is true', async () => {
        const res = await invokeEvaluate({
            requestId: 'access-request-precheck:req-1:submitted',
            accessRequestId: 'req-1',
            identityId: 'identity-1',
            inflightOnly: true,
            evaluateSod: true,
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
        })

        expect(createAccountV1).toHaveBeenCalledTimes(1)
        expect(getTaskStatusV1).toHaveBeenCalled()
        expect(persistedAccounts.get('access-request-precheck:req-1:submitted')).toMatchObject({
            'evaluate-access-request-risk:tier': 'High',
            'preventive-sod-check:has-violation': false,
        })
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                summary: expect.objectContaining({
                    tier: 'High',
                    hasViolation: false,
                    sodSituationSummary: 'No violations found',
                }),
            })
        )
    })

    it('defaults to risk-only without SoD when evaluateSod is omitted', async () => {
        const res = await invokeEvaluate({
            requestId: 'evaluate-access-request-risk:req-risk-only:dynamic',
            accessRequestId: 'req-risk-only',
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
        })

        const account = persistedAccounts.get('evaluate-access-request-risk:req-risk-only:dynamic')
        expect(account).toMatchObject({ 'evaluate-access-request-risk:tier': 'High' })
        expect(account).not.toHaveProperty('preventive-sod-check:has-violation')
        expect(startPredictSodViolationsV1).not.toHaveBeenCalled()

        const summary = res.send.mock.calls[0]?.[0]?.summary
        expect(summary).toMatchObject({ tier: 'High' })
        expect(summary).not.toHaveProperty('hasViolation')
    })

    it('skips risk scoring when evaluateRisk is false', async () => {
        const res = await invokeEvaluate({
            requestId: 'access-request-precheck:sod-only:submitted',
            accessRequestId: 'req-sod-only',
            identityId: 'identity-1',
            inflightOnly: true,
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
            evaluateRisk: false,
            evaluateSod: true,
        })

        const account = persistedAccounts.get('access-request-precheck:sod-only:submitted')
        expect(account).toMatchObject({
            'preventive-sod-check:has-violation': false,
            'preventive-sod-check:situation-summary': 'No violations found',
        })
        expect(account).not.toHaveProperty('evaluate-access-request-risk:tier')

        const summary = res.send.mock.calls[0]?.[0]?.summary
        expect(summary).toMatchObject({
            hasViolation: false,
            sodSituationSummary: 'No violations found',
        })
        expect(summary).not.toHaveProperty('tier')
    })

    it('fails when both evaluateRisk and evaluateSod are false', async () => {
        const res = await invokeEvaluate({
            requestId: 'evaluate-access-request:neither',
            evaluateRisk: false,
            evaluateSod: '0',
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('evaluateRisk or evaluateSod'),
            })
        )
        expect(startPredictSodViolationsV1).not.toHaveBeenCalled()
        expect(getEntitlementV1).not.toHaveBeenCalled()
    })

    it('requires identityId when evaluateSod is true', async () => {
        const res = await invokeEvaluate({
            requestId: 'evaluate-access-request:missing-identity',
            evaluateSod: true,
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('identityId'),
            })
        )
    })

    it('submits persistence without task polling when waitForPersist is false', async () => {
        await invokeEvaluate({
            requestId: 'evaluate-access-request-risk:req-fast:dynamic',
            accessRequestId: 'req-fast',
            requestedItems: [{ id: 'ent-1', type: 'ENTITLEMENT' }],
            waitForPersist: false,
        })

        expect(createAccountV1).toHaveBeenCalledTimes(1)
        expect(getTaskStatusV1).not.toHaveBeenCalled()
    })

    it('offline invoke scores risk and SoD without ISC config', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        beginPayloadOutputCapture()
        const res = { send: vi.fn() }
        try {
            await evaluateAccessRequestOperation(
                { commandType: 'custom:evaluate-access-request' } as never,
                {
                    requestId: 'access-request-precheck:offline:submitted',
                    accessRequestId: 'offline-ar',
                    identityId: OFFLINE_IDENTITY_ID,
                    inflightOnly: true,
                    evaluateSod: true,
                    requestedItems: [{ id: 'offline-ent-high', type: 'ENTITLEMENT' }],
                },
                res as never
            )
            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'success',
                    summary: expect.objectContaining({
                        tier: 'High',
                    }),
                })
            )
        } finally {
            endPayloadOutputCapture()
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })
})
