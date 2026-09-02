import { _withConfig } from '@sailpoint/connector-sdk'
import { readFileSync } from 'fs'
import { join } from 'path'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '../auto-registry'
import { beginPayloadOutputCapture, endPayloadOutputCapture } from '../../framework/payload-persist-collector'
import { accessModelSodRemediationApplyOperation } from './index'
import { FORM_INSTANCE_LIST_PAGE_SIZE } from '../../isc/forms'
import {
    getFormInstanceByIdOffline,
    markOfflineRoleAlreadyClean,
    OFFLINE_FORM_INSTANCES,
    resetOfflineCatalogState,
} from './offline-data'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const persistAttributes = [
    { name: 'access-model-sod-remediation-apply:status', type: 'STRING', isMulti: false },
    { name: 'access-model-sod-remediation-apply:access-item-id', type: 'STRING', isMulti: false },
    { name: 'access-model-sod-remediation-apply:access-item-type', type: 'STRING', isMulti: false },
    { name: 'access-model-sod-remediation-apply:removed-entitlement-ids', type: 'STRING', isMulti: true },
    { name: 'access-model-sod-remediation-apply:detached-access-profile-ids', type: 'STRING', isMulti: true },
    { name: 'access-model-sod-remediation-apply:description-appended', type: 'STRING', isMulti: false },
]

const createAccountV1 = vi.fn().mockResolvedValue({})
const putAccountV1 = vi.fn().mockResolvedValue({ data: { id: 'task-put-1' } })
const resolveSourceByName = vi.fn()
const getSourceSchemasV1 = vi.fn()
const persistedAccounts = new Map<string, Record<string, unknown>>()

const patchRoleV1 = vi.fn().mockResolvedValue({})
const patchAccessProfileV1 = vi.fn().mockResolvedValue({})
const getRoleV1 = vi.fn()
const getRoleEntitlementsV1 = vi.fn()
const getAccessProfileEntitlementsV1 = vi.fn()
const getAccessProfileV1 = vi.fn()
const getFormInstanceByKeyV1 = vi.fn()
const searchFormDefinitionsByTenantV1 = vi.fn()
const createFormDefinitionV1 = vi.fn()
const patchFormDefinitionV1 = vi.fn()
const searchFormInstancesByTenantV1 = vi.fn()
const DEFAULT_FORM_DEFINITION_ID = 'fd-1'
const DEFAULT_FORM_NAME = 'Access Model SOD Remediation'

function listRowFromOffline(formInstanceId: string): Record<string, unknown> {
    const instance = getFormInstanceByIdOffline(formInstanceId)
    return {
        id: instance.id,
        state: instance.state,
        formInput: instance.formInput,
        formData: instance.formData,
        recipients: instance.submitterId ? [{ id: instance.submitterId }] : undefined,
    }
}

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
            putAccountV1: (...args: unknown[]) => putAccountV1(...args),
            getAccountV1: vi.fn(),
        },
        tasks: {
            getTaskStatusV1: vi.fn().mockResolvedValue({
                data: { completed: '2026-08-18T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
            }),
        },
        roles: {
            getRoleV1: (...args: unknown[]) => getRoleV1(...args),
            getRoleEntitlementsV1: (...args: unknown[]) => getRoleEntitlementsV1(...args),
            patchRoleV1: (...args: unknown[]) => patchRoleV1(...args),
        },
        accessProfiles: {
            getAccessProfileV1: (...args: unknown[]) => getAccessProfileV1(...args),
            getAccessProfileEntitlementsV1: (...args: unknown[]) => getAccessProfileEntitlementsV1(...args),
            patchAccessProfileV1: (...args: unknown[]) => patchAccessProfileV1(...args),
        },
        forms: {
            getFormInstanceByKeyV1: (...args: unknown[]) => getFormInstanceByKeyV1(...args),
            searchFormDefinitionsByTenantV1: (...args: unknown[]) => searchFormDefinitionsByTenantV1(...args),
            createFormDefinitionV1: (...args: unknown[]) => createFormDefinitionV1(...args),
            patchFormDefinitionV1: (...args: unknown[]) => patchFormDefinitionV1(...args),
            searchFormInstancesByTenantV1: (...args: unknown[]) => searchFormInstancesByTenantV1(...args),
        },
    })),
}))

describe('accessModelSodRemediationApplyOperation', () => {
    beforeEach(() => {
        resetOfflineCatalogState()
        persistedAccounts.clear()
        createAccountV1.mockClear()
        putAccountV1.mockClear()
        patchRoleV1.mockClear()
        patchAccessProfileV1.mockClear()
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
            return { data: { id: 'task-create-1' } }
        })
        putAccountV1.mockImplementation(async ({ accountAttributes }) => {
            const attributes = accountAttributes.attributes as Record<string, unknown>
            const id = String(attributes.id)
            persistedAccounts.set(id, attributes)
            return { data: { id: 'task-put-1' } }
        })

        getRoleV1.mockResolvedValue({
            data: {
                description: 'Role desc',
                accessProfiles: [{ id: 'ap-live-1', name: 'AP' }],
            },
        })
        getRoleEntitlementsV1.mockResolvedValue({
            data: [{ id: 'ent-a', name: 'A' }],
        })
        getAccessProfileEntitlementsV1.mockImplementation(async ({ id }) => {
            if (id === 'ap-live-1') {
                return { data: [{ id: 'ent-c', name: 'C' }] }
            }
            return { data: [{ id: 'ent-x', name: 'X' }] }
        })
        getAccessProfileV1.mockResolvedValue({ data: { description: 'AP desc' } })
        getFormInstanceByKeyV1.mockClear()
        searchFormDefinitionsByTenantV1.mockReset()
        searchFormDefinitionsByTenantV1.mockResolvedValue({
            data: { results: [{ id: DEFAULT_FORM_DEFINITION_ID }] },
        })
        createFormDefinitionV1.mockClear()
        patchFormDefinitionV1.mockClear()
        searchFormInstancesByTenantV1.mockReset()
        searchFormInstancesByTenantV1.mockResolvedValue({
            data: Object.keys(OFFLINE_FORM_INSTANCES).map((id) => listRowFromOffline(id)),
        })
    })

    it('Offline apply simulates success for role direct entitlement removal', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }
        beginPayloadOutputCapture()

        try {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply' } as never,
                {
                    requestId: 'req-apply-offline-1',
                    formInstanceId: 'fi-role-group-a-direct',
                    formName: DEFAULT_FORM_NAME,
                },
                res as never
            )

            const inhibitedPersists = endPayloadOutputCapture()

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'success',
                    'access-model-sod-remediation-apply:status': 'applied',
                    'access-model-sod-remediation-apply:access-item-id': 'role-offline-1',
                    'access-model-sod-remediation-apply:removed-entitlement-ids': ['ent-a'],
                })
            )
            expect(inhibitedPersists[0]?.identity).toBe('fi-role-group-a-direct')
            expect(searchFormDefinitionsByTenantV1).not.toHaveBeenCalled()
            expect(searchFormInstancesByTenantV1).not.toHaveBeenCalled()
        } finally {
            endPayloadOutputCapture()
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })

    it('Offline apply detaches nested access profile from role', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }

        try {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply' } as never,
                {
                    requestId: 'req-apply-offline-2',
                    formInstanceId: 'fi-role-group-b-nested',
                    formName: DEFAULT_FORM_NAME,
                },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'success',
                    'access-model-sod-remediation-apply:status': 'applied',
                    'access-model-sod-remediation-apply:detached-access-profile-ids': ['ap-offline-1'],
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

    it('Second invoke skips patch', async () => {
        markOfflineRoleAlreadyClean('role-offline-1')
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }

        try {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply' } as never,
                {
                    requestId: 'req-apply-offline-skip',
                    formInstanceId: 'fi-role-already-clean',
                    formName: DEFAULT_FORM_NAME,
                },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'success',
                    'access-model-sod-remediation-apply:status': 'skipped-already-clean',
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

    it('Completed form required rejects non-completed instances', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }

        try {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply' } as never,
                {
                    requestId: 'req-apply-invalid',
                    formInstanceId: 'fi-in-progress',
                    formName: DEFAULT_FORM_NAME,
                },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'failed',
                    error: expect.stringMatching(/COMPLETED/),
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

    it('Duplicate apply after prior applied status', async () => {
        const resFirst = { send: vi.fn() }
        const resSecond = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-first',
                    formInstanceId: 'fi-role-group-a-direct',
                    formName: DEFAULT_FORM_NAME,
                },
                resFirst as never
            )
        })

        expect(patchRoleV1).toHaveBeenCalledTimes(1)
        patchRoleV1.mockClear()

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-second',
                    formInstanceId: 'fi-role-group-a-direct',
                    formName: DEFAULT_FORM_NAME,
                },
                resSecond as never
            )
        })

        expect(patchRoleV1).not.toHaveBeenCalled()
        expect(searchFormInstancesByTenantV1).toHaveBeenCalledTimes(1)
        expect(getFormInstanceByKeyV1).not.toHaveBeenCalled()
        expect(resSecond.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation-apply:status': 'skipped-already-applied',
                'access-model-sod-remediation-apply:access-item-id': 'role-offline-1',
            })
        )
    })

    it('Workflow invoke binding applies live role patch for nested access profile detach', async () => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-live',
                    formInstanceId: 'fi-role-group-b-nested',
                    formName: DEFAULT_FORM_NAME,
                },
                res as never
            )
        })

        expect(patchRoleV1).toHaveBeenCalled()
        expect(getFormInstanceByKeyV1).not.toHaveBeenCalled()
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation-apply:status': 'applied',
            })
        )
    })

    it('Entitlements removed from access profile under review in offline mode', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }

        try {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply' } as never,
                {
                    requestId: 'req-apply-ap',
                    formInstanceId: 'fi-ap-group-a',
                    formName: DEFAULT_FORM_NAME,
                },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'success',
                    'access-model-sod-remediation-apply:access-item-type': 'ACCESS_PROFILE',
                    'access-model-sod-remediation-apply:removed-entitlement-ids': ['ent-x'],
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

    it('List filtered by form definition id', async () => {
        const res = { send: vi.fn() }
        searchFormInstancesByTenantV1.mockResolvedValue({
            data: [listRowFromOffline('fi-role-group-a-direct')],
        })

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-list-filter',
                    formInstanceId: 'fi-role-group-a-direct',
                    formName: DEFAULT_FORM_NAME,
                },
                res as never
            )
        })

        expect(searchFormInstancesByTenantV1).toHaveBeenCalledWith({
            offset: 0,
            limit: FORM_INSTANCE_LIST_PAGE_SIZE,
            filters: `formDefinitionId eq "${DEFAULT_FORM_DEFINITION_ID}"`,
        })
        expect(searchFormDefinitionsByTenantV1).toHaveBeenCalledWith({
            filters: `name eq "${DEFAULT_FORM_NAME}"`,
        })
        expect(createFormDefinitionV1).not.toHaveBeenCalled()
        expect(patchFormDefinitionV1).not.toHaveBeenCalled()
        expect(getFormInstanceByKeyV1).not.toHaveBeenCalled()
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation-apply:status': 'applied',
            })
        )
    })

    it('Instance found on a later page', async () => {
        const res = { send: vi.fn() }
        const firstPage = Array.from({ length: FORM_INSTANCE_LIST_PAGE_SIZE }, (_, index) => ({
            id: `fi-other-${index}`,
            state: 'ASSIGNED',
            formInput: {},
            formData: {},
        }))
        searchFormInstancesByTenantV1
            .mockResolvedValueOnce({ data: firstPage })
            .mockResolvedValueOnce({ data: [listRowFromOffline('fi-role-group-b-nested')] })

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-later-page',
                    formInstanceId: 'fi-role-group-b-nested',
                    formName: DEFAULT_FORM_NAME,
                },
                res as never
            )
        })

        expect(searchFormInstancesByTenantV1).toHaveBeenNthCalledWith(2, {
            offset: FORM_INSTANCE_LIST_PAGE_SIZE,
            limit: FORM_INSTANCE_LIST_PAGE_SIZE,
            filters: `formDefinitionId eq "${DEFAULT_FORM_DEFINITION_ID}"`,
        })
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                'access-model-sod-remediation-apply:status': 'applied',
            })
        )
    })

    it('Missing instance after last page', async () => {
        const res = { send: vi.fn() }
        searchFormInstancesByTenantV1.mockResolvedValue({ data: [] })

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-missing',
                    formInstanceId: 'fi-missing',
                    formName: DEFAULT_FORM_NAME,
                },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringMatching(/not found/),
            })
        )
        expect(patchRoleV1).not.toHaveBeenCalled()
        expect(patchAccessProfileV1).not.toHaveBeenCalled()
        expect(getFormInstanceByKeyV1).not.toHaveBeenCalled()
    })

    it('Missing form definition by name fails before instance list and catalog patch', async () => {
        const res = { send: vi.fn() }
        searchFormDefinitionsByTenantV1.mockResolvedValue({ data: { results: [] } })

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-missing-definition',
                    formInstanceId: 'fi-role-group-a-direct',
                    formName: 'Unknown Form',
                },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringMatching(/formName/),
            })
        )
        expect(searchFormInstancesByTenantV1).not.toHaveBeenCalled()
        expect(patchRoleV1).not.toHaveBeenCalled()
        expect(patchAccessProfileV1).not.toHaveBeenCalled()
    })

    it('Prior apply skips list', async () => {
        const resFirst = { send: vi.fn() }
        const resSecond = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-skip-list-first',
                    formInstanceId: 'fi-role-group-a-direct',
                    formName: DEFAULT_FORM_NAME,
                },
                resFirst as never
            )
        })

        searchFormInstancesByTenantV1.mockClear()
        searchFormDefinitionsByTenantV1.mockClear()

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-skip-list-second',
                    formInstanceId: 'fi-role-group-a-direct',
                    formName: DEFAULT_FORM_NAME,
                },
                resSecond as never
            )
        })

        expect(searchFormInstancesByTenantV1).not.toHaveBeenCalled()
        expect(searchFormDefinitionsByTenantV1).not.toHaveBeenCalled()
        expect(resSecond.send).toHaveBeenCalledWith(
            expect.objectContaining({
                'access-model-sod-remediation-apply:status': 'skipped-already-applied',
            })
        )
    })

    it.each([undefined, '   '])('Missing formName validation for %j', async (formName) => {
        const res = { send: vi.fn() }

        await _withConfig(workflowConfig, async () => {
            await accessModelSodRemediationApplyOperation(
                { commandType: 'custom:access-model-sod-remediation-apply', config: workflowConfig } as never,
                {
                    requestId: 'req-apply-missing-def',
                    formInstanceId: 'fi-role-group-a-direct',
                    formName,
                },
                res as never
            )
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringMatching(/formName/),
            })
        )
        expect(searchFormInstancesByTenantV1).not.toHaveBeenCalled()
        expect(searchFormDefinitionsByTenantV1).not.toHaveBeenCalled()
        expect(patchRoleV1).not.toHaveBeenCalled()
    })

    it('Form submit returns remediation side through documented workflow binding', () => {
        const applyReadme = readFileSync(
            join(process.cwd(), 'src/operations/access-model-sod-remediation-apply/README.md'),
            'utf-8'
        )
        const scanReadme = readFileSync(
            join(process.cwd(), 'src/operations/access-model-sod-remediation/README.md'),
            'utf-8'
        )
        const workflow = readFileSync(
            join(process.cwd(), 'workflows/Access Model SOD - Remediation.json'),
            'utf-8'
        )
        const offlinePayload = readFileSync(
            join(process.cwd(), 'payloads/access-model-sod-remediation-apply-offline.json'),
            'utf-8'
        )

        expect(applyReadme).toMatch(/formName/)
        expect(applyReadme).toMatch(/searchFormInstancesByTenantV1/)
        expect(applyReadme).not.toMatch(/formInstanceId` only/)
        expect(scanReadme).toMatch(/same `formName`/)
        expect(workflow).toContain('"formName": "Access Model SOD Remediation"')
        expect(workflow).not.toContain('"formDefinitionId": "{{$.trigger.formDefinitionId}}"')
        expect(offlinePayload).toMatch(/"formName"/)
        expect(offlinePayload).not.toMatch(/"formDefinitionId"/)
    })
})
