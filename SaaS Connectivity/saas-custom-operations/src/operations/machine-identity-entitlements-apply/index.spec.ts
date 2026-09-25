import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { getMachineIdentity, patchUserEntitlements } from '../../isc/machine-identities'
import { machineIdentityEntitlementsApplyOperation, toUserEntitlementRefs } from './index'

const workflowConfig = {
    apiUrl: 'https://company22986-poc.api.identitynow.com',
    token: 'test-token',
    sourceName: 'SaaS Custom Operations',
}

const persistedAccounts = new Map<string, Record<string, unknown>>()
const createAccountV1 = vi.fn()
const listAccountsV1 = vi.fn()
const getSourceSchemasV1 = vi.fn()
const resolveSourceByName = vi.fn()

vi.mock('../../isc/machine-identities', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/machine-identities')>()
    return { ...actual, getMachineIdentity: vi.fn(), patchUserEntitlements: vi.fn() }
})

vi.mock('../../framework/result-source', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../framework/result-source')>()
    return { ...actual, resolveSourceByName: (...args: unknown[]) => resolveSourceByName(...args) }
})

vi.mock('../../framework/sdk-factory', () => ({
    createSailPointClients: vi.fn(() => ({
        sources: {
            getSourceSchemasV1: (...args: unknown[]) => getSourceSchemasV1(...args),
            updateSourceSchemaV1: vi.fn(),
            createSourceSchemaV1: vi.fn(),
        },
        accounts: {
            createAccountV1: (...args: unknown[]) => createAccountV1(...args),
            deleteAccountAsyncV1: vi.fn(),
            listAccountsV1: (...args: unknown[]) => listAccountsV1(...args),
            putAccountV1: vi.fn(),
            getAccountV1: vi.fn(),
        },
        machineIdentities: { getMachineIdentityV1: vi.fn(), updateMachineIdentityV1: vi.fn() },
        tasks: {
            getTaskStatusV1: vi.fn().mockResolvedValue({
                data: { completed: '2026-08-11T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
            }),
        },
    })),
}))

const getMachineIdentityMock = vi.mocked(getMachineIdentity)
const patchUserEntitlementsMock = vi.mocked(patchUserEntitlements)

async function invokeConnected(input: Record<string, unknown>, res = { send: vi.fn() }) {
    await _withConfig(workflowConfig, async () => {
        await machineIdentityEntitlementsApplyOperation(
            { commandType: 'custom:machine-identity-entitlements-apply' } as never,
            input,
            res as never
        )
    })
    return res
}

describe('custom:machine-identity-entitlements-apply', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockReset()
        listAccountsV1.mockReset()
        getMachineIdentityMock.mockReset()
        patchUserEntitlementsMock.mockReset()
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
                        {
                            name: 'machine-identity-entitlements-apply:machine-identity-id',
                            type: 'STRING',
                            isMulti: false,
                        },
                        { name: 'machine-identity-entitlements-apply:status', type: 'STRING', isMulti: false },
                        {
                            name: 'machine-identity-entitlements-apply:added-entitlement-ids',
                            type: 'STRING',
                            isMulti: true,
                        },
                    ],
                },
            ],
        })
        createAccountV1.mockImplementation(async ({ accountAttributesCreate }) => {
            const attributes = accountAttributesCreate.attributes as Record<string, unknown>
            persistedAccounts.set(String(attributes.id), attributes)
            return { data: { id: 'task-create-1' } }
        })
        listAccountsV1.mockImplementation(async ({ filters }) => {
            const match = /(?:nativeIdentity|id|name) eq "([^"]+)"/.exec(String(filters ?? ''))
            const id = match?.[1]
            if (!id || !persistedAccounts.has(id)) {
                return { data: [] }
            }
            return { data: [{ id: `isc-${id}`, sourceId: 'source-123', attributes: persistedAccounts.get(id) }] }
        })
    })

    it('Patches the union of existing refs and the add list', async () => {
        getMachineIdentityMock.mockResolvedValue({
            id: 'mi-1',
            userEntitlements: [{ sourceId: 'src-1', entitlementId: 'ent-existing' }],
        })

        const res = await invokeConnected({
            requestId: 'req-apply',
            machineIdentityId: 'mi-1',
            entitlementIds: ['ent-new'],
            entitlementSourceIds: ['src-1'],
        })

        expect(patchUserEntitlementsMock).toHaveBeenCalledWith(expect.anything(), 'mi-1', [
            { sourceId: 'src-1', entitlementId: 'ent-existing' },
            { sourceId: 'src-1', entitlementId: 'ent-new' },
        ])
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({ status: 'success', summary: expect.objectContaining({ addedCount: 1 }) })
        )
    })

    it('Existing refs are never replaced by the add list alone', async () => {
        getMachineIdentityMock.mockResolvedValue({
            id: 'mi-1',
            userEntitlements: [
                { sourceId: 'src-1', entitlementId: 'ent-a' },
                { sourceId: 'src-2', entitlementId: 'ent-b' },
            ],
        })

        await invokeConnected({
            requestId: 'req-keep',
            machineIdentityId: 'mi-1',
            entitlementIds: ['ent-c'],
            entitlementSourceIds: ['src-3'],
        })

        const patched = patchUserEntitlementsMock.mock.calls[0][2]
        expect(patched).toHaveLength(3)
        expect(patched).toEqual(
            expect.arrayContaining([
                { sourceId: 'src-1', entitlementId: 'ent-a' },
                { sourceId: 'src-2', entitlementId: 'ent-b' },
            ])
        )
    })

    it('Already present refs skip the patch', async () => {
        getMachineIdentityMock.mockResolvedValue({
            id: 'mi-1',
            userEntitlements: [{ sourceId: 'src-1', entitlementId: 'ent-a' }],
        })

        await invokeConnected({
            requestId: 'req-noop',
            machineIdentityId: 'mi-1',
            entitlementIds: ['ent-a'],
            entitlementSourceIds: ['src-1'],
        })

        expect(patchUserEntitlementsMock).not.toHaveBeenCalled()
        expect(persistedAccounts.get('req-noop:mi-1')?.['machine-identity-entitlements-apply:status']).toBe(
            'skipped-already-present'
        )
    })

    it('Unknown machine identity fails the invoke', async () => {
        getMachineIdentityMock.mockResolvedValue(undefined as never)

        const res = await invokeConnected({
            requestId: 'req-missing',
            machineIdentityId: 'mi-missing',
            entitlementIds: ['ent-a'],
            entitlementSourceIds: ['src-1'],
        })

        expect(patchUserEntitlementsMock).not.toHaveBeenCalled()
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({ status: 'failed', error: expect.stringContaining('Machine identity not found') })
        )
    })

    it('Mismatched array lengths fail the invoke', async () => {
        const res = await invokeConnected({
            requestId: 'req-mismatch',
            machineIdentityId: 'mi-1',
            entitlementIds: ['ent-a', 'ent-b'],
            entitlementSourceIds: ['src-1'],
        })

        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({ status: 'failed', error: expect.stringContaining('same length') })
        )
    })

    it('Single string attributes are accepted', () => {
        expect(toUserEntitlementRefs('ent-a', 'src-1')).toEqual([{ sourceId: 'src-1', entitlementId: 'ent-a' }])
    })

    it('Auto-discovery registration', async () => {
        const { OPERATION_HANDLERS } = await import('../auto-registry')
        const spec = await import('../../../connector-spec.json')
        expect(OPERATION_HANDLERS['custom:machine-identity-entitlements-apply']).toBeDefined()
        expect(spec.default.commands).toContain('custom:machine-identity-entitlements-apply')
    })

    it('Operation README documents contract', () => {
        const readme = readFileSync(join(__dirname, 'README.md'), 'utf8')
        expect(readme).toContain('custom:machine-identity-entitlements-apply')
        expect(readme).toContain('machineIdentityId')
        expect(readme).toContain('{requestId}:{machineIdentityId}')
        expect(readme).toMatch(/union/i)
    })
})
