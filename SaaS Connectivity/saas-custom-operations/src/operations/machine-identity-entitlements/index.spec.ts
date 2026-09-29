import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { listEntitlementsByValue, listEntitlementsByValues } from '../../isc/entitlements'
import { listMachineAccounts, MachineAccountRecord } from '../../isc/machine-accounts'
import {
    getMachineIdentity,
    listMachineIdentities,
    patchUserEntitlements,
    resolveMachineIdentityByIdentityId,
} from '../../isc/machine-identities'
import { getSource } from '../../isc/sources'
import { machineIdentityEntitlementsOperation } from './index'

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

vi.mock('../../isc/machine-accounts', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/machine-accounts')>()
    return { ...actual, listMachineAccounts: vi.fn() }
})

vi.mock('../../isc/machine-identities', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/machine-identities')>()
    return {
        ...actual,
        getMachineIdentity: vi.fn(),
        listMachineIdentities: vi.fn(),
        patchUserEntitlements: vi.fn(),
        resolveMachineIdentityByIdentityId: vi.fn(),
    }
})

vi.mock('../../isc/entitlements', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/entitlements')>()
    return {
        ...actual,
        listEntitlementsByValue: vi.fn(),
        listEntitlementsByValues: vi.fn(),
    }
})

vi.mock('../../isc/sources', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/sources')>()
    return {
        ...actual,
        getSource: vi.fn(),
    }
})

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
            createSourceSchemaV1: vi.fn(),
        },
        accounts: {
            createAccountV1: (...args: unknown[]) => createAccountV1(...args),
            deleteAccountAsyncV1: vi.fn(),
            listAccountsV1: (...args: unknown[]) => listAccountsV1(...args),
            putAccountV1: vi.fn(),
            getAccountV1: vi.fn(),
        },
        entitlements: { listEntitlementsV1: vi.fn() },
        machineIdentities: { listMachineIdentitiesV1: vi.fn(), getMachineIdentityV1: vi.fn() },
        machineAccounts: { listMachineAccountsV1: vi.fn() },
        tasks: {
            getTaskStatusV1: vi.fn().mockResolvedValue({
                data: { completed: '2026-08-11T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
            }),
        },
    })),
}))

const listMachineAccountsMock = vi.mocked(listMachineAccounts)
const getMachineIdentityMock = vi.mocked(getMachineIdentity)
const listMachineIdentitiesMock = vi.mocked(listMachineIdentities)
const patchUserEntitlementsMock = vi.mocked(patchUserEntitlements)
const resolveMachineIdentityMock = vi.mocked(resolveMachineIdentityByIdentityId)
const listEntitlementsByValueMock = vi.mocked(listEntitlementsByValue)
const listEntitlementsByValuesMock = vi.mocked(listEntitlementsByValues)
const getSourceMock = vi.mocked(getSource)
const RESULT_SOURCE_SCHEMA = {
    id: 'schema-1',
    name: 'account',
    attributes: [
        { name: 'id', type: 'STRING', isMulti: false },
        { name: 'status', type: 'STRING', isMulti: false },
        { name: 'date', type: 'STRING', isMulti: false },
        { name: 'machine-identity-entitlements:identities-scanned', type: 'INT', isMulti: false },
        { name: 'machine-identity-entitlements:identities-updated', type: 'INT', isMulti: false },
        { name: 'machine-identity-entitlements:identities-skipped', type: 'INT', isMulti: false },
        { name: 'machine-identity-entitlements:identities-failed', type: 'INT', isMulti: false },
        { name: 'machine-identity-entitlements:entitlements-added', type: 'INT', isMulti: false },
        { name: 'machine-identity-entitlements:failed-identity-ids', type: 'STRING', isMulti: true },
        { name: 'machine-identity-entitlements:failure-details', type: 'STRING', isMulti: true },
    ],
}

async function invokeConnected(input: Record<string, unknown>, res = { send: vi.fn() }) {
    await _withConfig(workflowConfig, async () => {
        await machineIdentityEntitlementsOperation(
            { commandType: 'custom:machine-identity-entitlements' } as never,
            input,
            res as never
        )
    })
    return res
}

function machineAccount(
    id: string,
    machineIdentityId: string,
    sourceId: string,
    connectorAttributes: Record<string, unknown>
): MachineAccountRecord {
    return { id, machineIdentity: { id: machineIdentityId }, source: { id: sourceId }, connectorAttributes }
}

describe('custom:machine-identity-entitlements', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockReset()
        listAccountsV1.mockReset()
        listMachineAccountsMock.mockReset()
        getMachineIdentityMock.mockReset()
        getMachineIdentityMock.mockImplementation(async (_client, id) => ({ id, userEntitlements: [] }))
        listMachineIdentitiesMock.mockReset()
        patchUserEntitlementsMock.mockReset()
        resolveMachineIdentityMock.mockReset()
        listEntitlementsByValueMock.mockReset()
        listEntitlementsByValuesMock.mockReset()
        getSourceMock.mockReset()
        getSourceMock.mockResolvedValue({
            name: 'Source',
            type: 'SOURCE',
            owner: { type: 'IDENTITY', id: 'owner-1' },
            connectorAttributes: { userEntitlements: 'appRole' },
        })
        resolveSourceByName.mockResolvedValue('source-123')
        getSourceSchemasV1.mockResolvedValue({
            data: [RESULT_SOURCE_SCHEMA],
        })
        createAccountV1.mockImplementation(async ({ accountAttributesCreate }) => {
            const attributes = accountAttributesCreate.attributes as Record<string, unknown>
            persistedAccounts.set(String(attributes.id), attributes)
            return { data: { id: 'task-create-1' } }
        })
        listAccountsV1.mockImplementation(async ({ filters }) => {
            const filterText = String(filters ?? '')
            const match = /(?:nativeIdentity|id|name) eq "([^"]+)"/.exec(filterText)
            const id = match?.[1]
            if (!id || !persistedAccounts.has(id)) {
                return { data: [] }
            }
            return { data: [{ id: `isc-${id}`, sourceId: 'source-123', attributes: persistedAccounts.get(id) }] }
        })
    })

    it('Full scan patches every identity with work and persists one summary', async () => {
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'CN=Admins' }),
            machineAccount('ma-2', 'mi-2', 'src-1', { appRole: 'CN=A' }),
        ])
        listMachineIdentitiesMock.mockResolvedValue([
            { id: 'mi-1', userEntitlements: [] },
            { id: 'mi-2', userEntitlements: [] },
        ])
        listEntitlementsByValuesMock.mockResolvedValue([
            { id: 'ent-1', sourceId: 'src-1', value: 'CN=Admins' },
            { id: 'ent-2', sourceId: 'src-1', value: 'CN=A' },
        ])
        getMachineIdentityMock.mockImplementation(async (_client, id) => ({ id, userEntitlements: [] }))

        const res = await invokeConnected({ requestId: 'req-scan' })

        expect(listMachineAccountsMock).toHaveBeenCalled()
        expect(resolveMachineIdentityMock).not.toHaveBeenCalled()
        expect(patchUserEntitlementsMock).toHaveBeenCalledTimes(2)
        expect([...persistedAccounts.keys()]).toEqual(['req-scan'])
        expect(persistedAccounts.get('req-scan')).toEqual(
            expect.objectContaining({
                status: 'success',
                'machine-identity-entitlements:identities-scanned': 2,
                'machine-identity-entitlements:identities-updated': 2,
                'machine-identity-entitlements:identities-failed': 0,
                'machine-identity-entitlements:entitlements-added': 2,
            })
        )
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                responses: ['req-scan'],
                summary: expect.objectContaining({ identitiesUpdated: 2, entitlementsAdded: 2 }),
            })
        )
    })

    it('Full scan resolves identities and entitlement values in batches', async () => {
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-enabled', { appRole: 'CN=A' }),
            machineAccount('ma-2', 'mi-2', 'src-enabled', { appRole: 'CN=B' }),
            machineAccount('ma-3', 'mi-skipped', 'src-disabled', { appRole: 'CN=Ignored' }),
        ])
        getSourceMock.mockImplementation(async (_client, sourceId) => ({
            name: 'Source',
            type: 'SOURCE',
            owner: { type: 'IDENTITY', id: 'owner-1' },
            connectorAttributes: sourceId === 'src-enabled' ? { userEntitlements: 'appRole' } : {},
        }))
        listMachineIdentitiesMock.mockResolvedValue([
            { id: 'mi-1', userEntitlements: [] },
            { id: 'mi-2', userEntitlements: [] },
        ])
        listEntitlementsByValuesMock.mockResolvedValue([
            { id: 'ent-a', sourceId: 'src-enabled', value: 'CN=A' },
            { id: 'ent-b', sourceId: 'src-enabled', value: 'CN=B' },
        ])
        getMachineIdentityMock.mockImplementation(async (_client, id) => ({ id, userEntitlements: [] }))

        await invokeConnected({ requestId: 'req-batched' })

        expect(getMachineIdentityMock).toHaveBeenCalledTimes(2)
        expect(listMachineIdentitiesMock).toHaveBeenCalledTimes(1)
        expect(listEntitlementsByValuesMock).toHaveBeenCalledWith(expect.anything(), ['CN=A', 'CN=B'])
        expect([...persistedAccounts.keys()]).toEqual(['req-batched'])
    })

    it('Patches use bounded concurrency', async () => {
        const identityCount = 12
        listMachineAccountsMock.mockResolvedValue(
            Array.from({ length: identityCount }, (_unused, index) =>
                machineAccount(`ma-${index}`, `mi-${index}`, 'src-1', { appRole: `CN=${index}` })
            )
        )
        listMachineIdentitiesMock.mockResolvedValue(
            Array.from({ length: identityCount }, (_unused, index) => ({ id: `mi-${index}`, userEntitlements: [] }))
        )
        listEntitlementsByValuesMock.mockResolvedValue(
            Array.from({ length: identityCount }, (_unused, index) => ({
                id: `ent-${index}`,
                sourceId: 'src-1',
                value: `CN=${index}`,
            }))
        )
        getMachineIdentityMock.mockImplementation(async (_client, id) => ({ id, userEntitlements: [] }))
        let inFlight = 0
        let peakInFlight = 0
        patchUserEntitlementsMock.mockImplementation(async () => {
            inFlight += 1
            peakInFlight = Math.max(peakInFlight, inFlight)
            await new Promise((resolve) => setTimeout(resolve, 5))
            inFlight -= 1
        })

        await invokeConnected({ requestId: 'req-parallel' })

        expect(patchUserEntitlementsMock).toHaveBeenCalledTimes(identityCount)
        expect([...persistedAccounts.keys()]).toEqual(['req-parallel'])
        expect(peakInFlight).toBeGreaterThan(1)
        expect(peakInFlight).toBeLessThanOrEqual(5)
    })

    it('Source schema is ensured once per invoke', async () => {
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'CN=A' }),
            machineAccount('ma-2', 'mi-2', 'src-1', { appRole: 'CN=B' }),
            machineAccount('ma-3', 'mi-3', 'src-1', { appRole: 'CN=C' }),
        ])
        listMachineIdentitiesMock.mockResolvedValue([
            { id: 'mi-1', userEntitlements: [] },
            { id: 'mi-2', userEntitlements: [] },
            { id: 'mi-3', userEntitlements: [] },
        ])
        listEntitlementsByValuesMock.mockResolvedValue([
            { id: 'ent-a', sourceId: 'src-1', value: 'CN=A' },
            { id: 'ent-b', sourceId: 'src-1', value: 'CN=B' },
            { id: 'ent-c', sourceId: 'src-1', value: 'CN=C' },
        ])
        getMachineIdentityMock.mockImplementation(async (_client, id) => ({ id, userEntitlements: [] }))

        await invokeConnected({ requestId: 'req-schema-once' })

        expect(persistedAccounts.size).toBe(1)
        expect(getSourceSchemasV1).toHaveBeenCalledTimes(1)
    })

    it('Empty delta skips patch and records one successful summary', async () => {
        listMachineAccountsMock.mockResolvedValue([machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'CN=Admins' })])
        listMachineIdentitiesMock.mockResolvedValue([
            {
                id: 'mi-1',
                userEntitlements: [{ sourceId: 'src-1', entitlementId: 'ent-1' }],
            },
        ])
        listEntitlementsByValuesMock.mockResolvedValue([{ id: 'ent-1', sourceId: 'src-1', value: 'CN=Admins' }])

        const res = await invokeConnected({ requestId: 'req-empty-delta' })

        expect(patchUserEntitlementsMock).not.toHaveBeenCalled()
        expect([...persistedAccounts.keys()]).toEqual(['req-empty-delta'])
        expect(persistedAccounts.get('req-empty-delta')).toEqual(
            expect.objectContaining({
                status: 'success',
                'machine-identity-entitlements:identities-updated': 0,
                'machine-identity-entitlements:identities-skipped': 1,
            })
        )
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                responses: ['req-empty-delta'],
                summary: expect.objectContaining({ identitiesUpdated: 0, identitiesSkipped: 1 }),
            })
        )
    })

    it('Tenant scan with no work succeeds', async () => {
        listMachineAccountsMock.mockResolvedValue([])

        const res = await invokeConnected({ requestId: 'req-no-work' })

        expect([...persistedAccounts.keys()]).toEqual(['req-no-work'])
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                summary: {
                    identitiesScanned: 0,
                    identitiesUpdated: 0,
                    identitiesSkipped: 0,
                    identitiesFailed: 0,
                    entitlementsAdded: 0,
                },
            })
        )
    })

    it('Targeted unknown identity rejected', async () => {
        resolveMachineIdentityMock.mockResolvedValue(undefined)
        const res = await invokeConnected({ requestId: 'req-unknown', identityId: 'missing' })

        expect(listMachineAccountsMock).not.toHaveBeenCalled()
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                error: expect.stringContaining('Machine identity not found'),
            })
        )
    })

    it('Optional identityId limits the scan', async () => {
        resolveMachineIdentityMock.mockResolvedValue({
            id: 'mi-1',
            userEntitlements: [],
        })
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'CN=Admins' }),
            machineAccount('ma-2', 'mi-2', 'src-1', { appRole: 'CN=Other' }),
        ])
        listEntitlementsByValueMock.mockResolvedValue([{ id: 'ent-1', sourceId: 'src-1' }])

        await invokeConnected({ requestId: 'req-one', identityId: 'mi-1' })

        expect(resolveMachineIdentityMock).toHaveBeenCalledWith(expect.anything(), 'mi-1')
        expect(listEntitlementsByValueMock).toHaveBeenCalledTimes(1)
        expect(patchUserEntitlementsMock).toHaveBeenCalledWith(expect.anything(), 'mi-1', [
            { sourceId: 'src-1', entitlementId: 'ent-1' },
        ])
        expect([...persistedAccounts.keys()]).toEqual(['req-one'])
    })

    it('Values union across linked machine accounts', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'CN=A' }),
            machineAccount('ma-2', 'mi-1', 'src-2', { appRole: 'CN=B' }),
        ])
        listEntitlementsByValueMock.mockImplementation(async (_client, value) => {
            const sourceId = value === 'CN=A' ? 'src-1' : 'src-2'
            return [{ id: value === 'CN=A' ? 'ent-a' : 'ent-b', sourceId, value }]
        })

        await invokeConnected({ requestId: 'req-union', identityId: 'mi-1' })

        expect(patchUserEntitlementsMock).toHaveBeenCalledWith(
            expect.anything(),
            'mi-1',
            expect.arrayContaining([
                { sourceId: 'src-1', entitlementId: 'ent-a' },
                { sourceId: 'src-2', entitlementId: 'ent-b' },
            ])
        )
    })

    it('Unmatched value is skipped', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-1', { appRole: ['CN=Admins', 'no-such-entitlement'] }),
        ])
        listEntitlementsByValueMock.mockImplementation(async (_client, value) =>
            value === 'CN=Admins' ? [{ id: 'ent-1', sourceId: 'src-1' }] : []
        )

        const res = await invokeConnected({ requestId: 'req-unmatched', identityId: 'mi-1' })

        expect(patchUserEntitlementsMock).toHaveBeenCalledWith(expect.anything(), 'mi-1', [
            { sourceId: 'src-1', entitlementId: 'ent-1' },
        ])
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({ status: 'success' }))
    })

    it('Successful scan summary uses namespaced counts', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-1', { appRole: ['CN=A', 'CN=B'] }),
        ])
        listEntitlementsByValueMock.mockImplementation(async (_client, value) => [
            {
                id: value === 'CN=A' ? 'ent-a' : 'ent-b',
                sourceId: 'src-1',
                value,
            },
        ])

        await invokeConnected({ requestId: 'req-contract', identityId: 'mi-1' })

        expect(persistedAccounts.get('req-contract')).toEqual(
            expect.objectContaining({
                status: 'success',
                operationName: 'custom:machine-identity-entitlements',
                'machine-identity-entitlements:identities-scanned': 1,
                'machine-identity-entitlements:identities-updated': 1,
                'machine-identity-entitlements:identities-skipped': 0,
                'machine-identity-entitlements:identities-failed': 0,
                'machine-identity-entitlements:entitlements-added': 2,
                'machine-identity-entitlements:failed-identity-ids': [],
                'machine-identity-entitlements:failure-details': [],
            })
        )
    })

    it('Source without connectorAttributes.userEntitlements is skipped during invoke', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        listMachineAccountsMock.mockResolvedValue([machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'CN=Admins' })])
        getSourceMock.mockResolvedValue({
            name: 'Source',
            type: 'SOURCE',
            owner: { type: 'IDENTITY', id: 'owner-1' },
            connectorAttributes: {},
        })

        const res = await invokeConnected({ requestId: 'req-skip-source', identityId: 'mi-1' })

        expect(listEntitlementsByValueMock).not.toHaveBeenCalled()
        expect(persistedAccounts.size).toBe(1)
        expect(patchUserEntitlementsMock).not.toHaveBeenCalled()
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({ status: 'success' }))
    })

    it('Configured connector attribute is read from the machine account', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'ignored', spn_app_groups: 'group-1' }),
        ])
        getSourceMock.mockResolvedValue({
            name: 'Source',
            type: 'SOURCE',
            owner: { type: 'IDENTITY', id: 'owner-1' },
            connectorAttributes: { userEntitlements: 'spn_app_groups' },
        })
        listEntitlementsByValueMock.mockResolvedValue([{ id: 'ent-1', sourceId: 'src-1' }])

        await invokeConnected({ requestId: 'req-configured', identityId: 'mi-1' })

        expect(listEntitlementsByValueMock).toHaveBeenCalledWith(expect.anything(), 'group-1')
        expect(persistedAccounts.size).toBe(1)
        expect(patchUserEntitlementsMock).toHaveBeenCalledTimes(1)
    })

    it('Entitlement value matches across every source that carries it', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-nhi', { appRole: 'shared-value' }),
        ])
        listEntitlementsByValueMock.mockResolvedValue([
            { id: 'ent-users', sourceId: 'src-users' },
            { id: 'ent-nhi', sourceId: 'src-nhi' },
        ])

        await invokeConnected({ requestId: 'req-source', identityId: 'mi-1' })

        expect(patchUserEntitlementsMock).toHaveBeenCalledWith(expect.anything(), 'mi-1', [
            { sourceId: 'src-users', entitlementId: 'ent-users' },
            { sourceId: 'src-nhi', entitlementId: 'ent-nhi' },
        ])
    })

    it('Current refs are re-read and preserved before patch', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'CN=New' }),
        ])
        listEntitlementsByValueMock.mockResolvedValue([{ id: 'ent-new', sourceId: 'src-1', value: 'CN=New' }])
        getMachineIdentityMock.mockResolvedValue({
            id: 'mi-1',
            userEntitlements: [{ sourceId: 'src-other', entitlementId: 'ent-concurrent' }],
        })

        await invokeConnected({ requestId: 'req-reread', identityId: 'mi-1' })

        expect(getMachineIdentityMock).toHaveBeenCalledWith(expect.anything(), 'mi-1')
        expect(patchUserEntitlementsMock).toHaveBeenCalledWith(expect.anything(), 'mi-1', [
            { sourceId: 'src-other', entitlementId: 'ent-concurrent' },
            { sourceId: 'src-1', entitlementId: 'ent-new' },
        ])
    })

    it('Mixed patch outcomes are partial success', async () => {
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-ok', 'src-1', { appRole: 'CN=OK' }),
            machineAccount('ma-2', 'mi-fail', 'src-1', { appRole: 'CN=Fail' }),
            machineAccount('ma-3', 'mi-ok-2', 'src-1', { appRole: 'CN=OK2' }),
        ])
        listMachineIdentitiesMock.mockResolvedValue([
            { id: 'mi-ok', userEntitlements: [] },
            { id: 'mi-fail', userEntitlements: [] },
            { id: 'mi-ok-2', userEntitlements: [] },
        ])
        listEntitlementsByValuesMock.mockResolvedValue([
            { id: 'ent-ok', sourceId: 'src-1', value: 'CN=OK' },
            { id: 'ent-fail', sourceId: 'src-1', value: 'CN=Fail' },
            { id: 'ent-ok-2', sourceId: 'src-1', value: 'CN=OK2' },
        ])
        patchUserEntitlementsMock.mockImplementation(async (_client, id) => {
            if (id === 'mi-fail') {
                throw new Error('patch denied')
            }
        })

        const res = await invokeConnected({ requestId: 'req-partial' })

        expect(patchUserEntitlementsMock).toHaveBeenCalledTimes(3)
        expect(persistedAccounts.get('req-partial')).toEqual(
            expect.objectContaining({
                status: 'partial',
                'machine-identity-entitlements:identities-updated': 2,
                'machine-identity-entitlements:identities-failed': 1,
                'machine-identity-entitlements:failed-identity-ids': ['mi-fail'],
                'machine-identity-entitlements:failure-details': [expect.stringContaining('patch denied')],
            })
        )
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                responses: ['req-partial'],
                summary: expect.objectContaining({ identitiesUpdated: 2, identitiesFailed: 1 }),
            })
        )
    })

    it('Every attempted patch failing persists failed summary before failed response', async () => {
        listMachineAccountsMock.mockResolvedValue([
            machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'CN=A' }),
            machineAccount('ma-2', 'mi-2', 'src-1', { appRole: 'CN=B' }),
        ])
        listMachineIdentitiesMock.mockResolvedValue([
            { id: 'mi-1', userEntitlements: [] },
            { id: 'mi-2', userEntitlements: [] },
        ])
        listEntitlementsByValuesMock.mockResolvedValue([
            { id: 'ent-a', sourceId: 'src-1', value: 'CN=A' },
            { id: 'ent-b', sourceId: 'src-1', value: 'CN=B' },
        ])
        patchUserEntitlementsMock.mockRejectedValue(new Error('tenant unavailable'))

        const res = await invokeConnected({ requestId: 'req-failed' })

        expect(patchUserEntitlementsMock).toHaveBeenCalledTimes(2)
        expect(persistedAccounts.get('req-failed')).toEqual(
            expect.objectContaining({
                status: 'failed',
                'machine-identity-entitlements:identities-updated': 0,
                'machine-identity-entitlements:identities-failed': 2,
                'machine-identity-entitlements:failed-identity-ids': ['mi-1', 'mi-2'],
            })
        )
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'failed',
                responses: ['req-failed'],
                summary: expect.objectContaining({ identitiesFailed: 2 }),
            })
        )
    })

    it('Offline invoke supported', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        try {
            const res = { send: vi.fn() }
            await machineIdentityEntitlementsOperation(
                { commandType: 'custom:machine-identity-entitlements' } as never,
                { requestId: 'req-offline' },
                res as never
            )

            expect(listMachineAccountsMock).not.toHaveBeenCalled()
            expect(listEntitlementsByValueMock).not.toHaveBeenCalled()
            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'success',
                    responses: ['req-offline'],
                    summary: expect.objectContaining({ identitiesUpdated: 2, identitiesFailed: 0 }),
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

    it('Auto-discovery registration', async () => {
        const { OPERATION_HANDLERS } = await import('../auto-registry')
        const spec = await import('../../../connector-spec.json')
        expect(OPERATION_HANDLERS['custom:machine-identity-entitlements']).toBeDefined()
        expect(spec.default.commands).toContain('custom:machine-identity-entitlements')
    })

    it('Machine identity entitlements follows namespacing convention', async () => {
        const { machineIdentityEntitlementsOperationSchema } = await import('./index.schema')
        const names = machineIdentityEntitlementsOperationSchema.outputFields.map((field) => field.name)
        expect(names).toEqual(
            expect.arrayContaining([
                'machine-identity-entitlements:identities-scanned',
                'machine-identity-entitlements:identities-updated',
                'machine-identity-entitlements:identities-skipped',
                'machine-identity-entitlements:identities-failed',
                'machine-identity-entitlements:entitlements-added',
                'machine-identity-entitlements:failed-identity-ids',
                'machine-identity-entitlements:failure-details',
            ])
        )
        expect(names.every((name) => name.startsWith('machine-identity-entitlements:'))).toBe(true)
    })

    it('Operation README documents contract', () => {
        const readme = readFileSync(join(__dirname, 'README.md'), 'utf8')
        expect(readme).toContain('custom:machine-identity-entitlements')
        expect(readme).toContain('identityId')
        expect(readme).toContain('scan summary account')
        expect(readme).toContain('scan summary identity')
        expect(readme).toContain('`{requestId}`')
        expect(readme).toContain('entitlements to add')
        expect(readme).toContain('underlying account')
        expect(readme).toContain('inbound entitlements attribute')
        expect(readme).toContain('machine-identity-entitlements:identities-updated')
        expect(readme).toContain('machine-identity-entitlements:identities-failed')
        expect(readme).toContain('partial')
        expect(readme).toContain('connectorAttributes.userEntitlements')
        expect(readme).toMatch(/workflow/i)
        expect(readme).toMatch(/scope/i)
        expect(readme).toContain('machineIdentity')
    })

    it('C4 diagram remains linked from the change design', () => {
        const design = readFileSync(
            join(__dirname, '../../../openspec/changes/archive/2026-09-25-machine-identity-entitlements/design.md'),
            'utf8'
        )
        const diagram = join(
            __dirname,
            '../../../openspec/changes/archive/2026-09-25-machine-identity-entitlements/diagrams/machine-identity-entitlements.drawio'
        )
        expect(design).toContain('diagrams/machine-identity-entitlements.drawio')
        expect(existsSync(diagram)).toBe(true)
    })
})
