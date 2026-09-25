import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { listEntitlementsByValue, listEntitlementsByValues } from '../../isc/entitlements'
import { listMachineAccounts, MachineAccountRecord } from '../../isc/machine-accounts'
import {
    getMachineIdentity,
    listMachineIdentities,
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
        { name: 'machine-identity-entitlements:machine-identity-id', type: 'STRING', isMulti: false },
        { name: 'machine-identity-entitlements:entitlement-ids', type: 'STRING', isMulti: true },
        { name: 'machine-identity-entitlements:entitlement-source-ids', type: 'STRING', isMulti: true },
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
        listMachineIdentitiesMock.mockReset()
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
            data: [
                {
                    id: 'schema-1',
                    name: 'account',
                    attributes: [
                        { name: 'id', type: 'STRING', isMulti: false },
                        { name: 'status', type: 'STRING', isMulti: false },
                        { name: 'date', type: 'STRING', isMulti: false },
                        { name: 'machine-identity-entitlements:machine-identity-id', type: 'STRING', isMulti: false },
                        { name: 'machine-identity-entitlements:entitlement-ids', type: 'STRING', isMulti: true },
                        { name: 'machine-identity-entitlements:entitlement-source-ids', type: 'STRING', isMulti: true },
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
            const filterText = String(filters ?? '')
            const identityMatch = /identityId eq "([^"]+)"/.exec(filterText)
            if (identityMatch?.[1]) {
                return { data: underlyingAccountsByIdentity.get(identityMatch[1]) ?? [] }
            }
            const match = /(?:nativeIdentity|id|name) eq "([^"]+)"/.exec(filterText)
            const id = match?.[1]
            if (!id || !persistedAccounts.has(id)) {
                return { data: [] }
            }
            return { data: [{ id: `isc-${id}`, sourceId: 'source-123', attributes: persistedAccounts.get(id) }] }
        })
    })

    it('Full scan persists one trigger account per identity with work', async () => {
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

        const res = await invokeConnected({ requestId: 'req-scan' })

        expect(listMachineAccountsMock).toHaveBeenCalled()
        expect(resolveMachineIdentityMock).not.toHaveBeenCalled()
        expect([...persistedAccounts.keys()].sort()).toEqual(['req-scan:mi-1', 'req-scan:mi-2'])
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                responses: expect.arrayContaining(['req-scan:mi-1', 'req-scan:mi-2']),
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

        await invokeConnected({ requestId: 'req-batched' })

        expect(getMachineIdentityMock).not.toHaveBeenCalled()
        expect(listMachineIdentitiesMock).toHaveBeenCalledTimes(1)
        expect(listEntitlementsByValuesMock).toHaveBeenCalledWith(expect.anything(), ['CN=A', 'CN=B'])
        expect([...persistedAccounts.keys()].sort()).toEqual(['req-batched:mi-1', 'req-batched:mi-2'])
    })

    it('Trigger accounts are persisted concurrently', async () => {
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
        let inFlight = 0
        let peakInFlight = 0
        createAccountV1.mockImplementation(async ({ accountAttributesCreate }) => {
            inFlight += 1
            peakInFlight = Math.max(peakInFlight, inFlight)
            await new Promise((resolve) => setTimeout(resolve, 5))
            const attributes = accountAttributesCreate.attributes as Record<string, unknown>
            persistedAccounts.set(String(attributes.id), attributes)
            inFlight -= 1
            return { data: { id: 'task-create-1' } }
        })

        await invokeConnected({ requestId: 'req-parallel' })

        expect(persistedAccounts.size).toBe(identityCount)
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

        await invokeConnected({ requestId: 'req-schema-once' })

        expect(persistedAccounts.size).toBe(3)
        expect(getSourceSchemasV1).toHaveBeenCalledTimes(1)
    })

    it('Empty delta skips persist', async () => {
        listMachineAccountsMock.mockResolvedValue([machineAccount('ma-1', 'mi-1', 'src-1', { appRole: 'CN=Admins' })])
        listMachineIdentitiesMock.mockResolvedValue([
            {
                id: 'mi-1',
                userEntitlements: [{ sourceId: 'src-1', entitlementId: 'ent-1' }],
            },
        ])
        listEntitlementsByValuesMock.mockResolvedValue([{ id: 'ent-1', sourceId: 'src-1', value: 'CN=Admins' }])

        const res = await invokeConnected({ requestId: 'req-empty-delta' })

        expect(persistedAccounts.size).toBe(0)
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({ status: 'success', responses: [] }))
    })

    it('Tenant scan with no work succeeds', async () => {
        listMachineAccountsMock.mockResolvedValue([])

        const res = await invokeConnected({ requestId: 'req-no-work' })

        expect(persistedAccounts.size).toBe(0)
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({ status: 'success' }))
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
        expect([...persistedAccounts.keys()]).toEqual(['req-one:mi-1'])
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

        expect(persistedAccounts.get('req-union:mi-1')?.['machine-identity-entitlements:entitlement-ids']).toEqual(
            expect.arrayContaining(['ent-a', 'ent-b'])
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

        expect(persistedAccounts.get('req-unmatched:mi-1')?.['machine-identity-entitlements:entitlement-ids']).toEqual([
            'ent-1',
        ])
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({ status: 'success' }))
    })

    it('Output contract is identity and parallel entitlement arrays', async () => {
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

        const account = persistedAccounts.get('req-contract:mi-1')
        const ids = account?.['machine-identity-entitlements:entitlement-ids'] as string[]
        const sources = account?.['machine-identity-entitlements:entitlement-source-ids'] as string[]
        expect(account?.['machine-identity-entitlements:machine-identity-id']).toBe('mi-1')
        expect(ids).toHaveLength(2)
        expect(sources).toHaveLength(2)
        expect(sources).toEqual(['src-1', 'src-1'])
        expect(account?.operationName).toBe('custom:machine-identity-entitlements')
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
        expect(persistedAccounts.size).toBe(0)
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

        const account = persistedAccounts.get('req-source:mi-1')
        expect(account?.['machine-identity-entitlements:entitlement-ids']).toEqual(['ent-users', 'ent-nhi'])
        expect(account?.['machine-identity-entitlements:entitlement-source-ids']).toEqual(['src-users', 'src-nhi'])
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
                    responses: expect.arrayContaining(['req-offline:mi-offline-1', 'req-offline:mi-offline-2']),
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
                'machine-identity-entitlements:machine-identity-id',
                'machine-identity-entitlements:entitlement-ids',
                'machine-identity-entitlements:entitlement-source-ids',
            ])
        )
        expect(names.every((name) => name.startsWith('machine-identity-entitlements:'))).toBe(true)
    })

    it('Operation README documents contract', () => {
        const readme = readFileSync(join(__dirname, 'README.md'), 'utf8')
        expect(readme).toContain('custom:machine-identity-entitlements')
        expect(readme).toContain('identityId')
        expect(readme).toContain('{requestId}:{machineIdentityId}')
        expect(readme).toContain('machine-identity-entitlements:machine-identity-id')
        expect(readme).toContain('machine-identity-entitlements:entitlement-ids')
        expect(readme).toContain('machine-identity-entitlements:entitlement-source-ids')
        expect(readme).toContain('connectorAttributes.userEntitlements')
        expect(readme).toMatch(/workflow/i)
        expect(readme).toMatch(/scope/i)
        expect(readme).toContain('machineIdentity')
    })

    it('C4 diagram remains linked from the change design', () => {
        const design = readFileSync(
            join(__dirname, '../../../openspec/changes/machine-identity-entitlements/design.md'),
            'utf8'
        )
        const diagram = join(
            __dirname,
            '../../../openspec/changes/machine-identity-entitlements/diagrams/machine-identity-entitlements.drawio'
        )
        expect(design).toContain('diagrams/machine-identity-entitlements.drawio')
        expect(existsSync(diagram)).toBe(true)
    })
})
