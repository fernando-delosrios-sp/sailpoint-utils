import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { _withConfig } from '@sailpoint/connector-sdk'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { listEntitlementsByValue } from '../../isc/entitlements'
import { listMachineIdentities, resolveMachineIdentityByIdentityId } from '../../isc/machine-identities'
import { getAccountSchema } from '../../isc/sources'
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

vi.mock('../../isc/machine-identities', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/machine-identities')>()
    return {
        ...actual,
        listMachineIdentities: vi.fn(),
        resolveMachineIdentityByIdentityId: vi.fn(),
    }
})

vi.mock('../../isc/entitlements', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/entitlements')>()
    return {
        ...actual,
        listEntitlementsByValue: vi.fn(),
    }
})

vi.mock('../../isc/sources', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../isc/sources')>()
    return {
        ...actual,
        getAccountSchema: vi.fn(),
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
        tasks: {
            getTaskStatusV1: vi.fn().mockResolvedValue({
                data: { completed: '2026-08-11T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
            }),
        },
    })),
}))

const listMachineIdentitiesMock = vi.mocked(listMachineIdentities)
const resolveMachineIdentityMock = vi.mocked(resolveMachineIdentityByIdentityId)
const listEntitlementsByValueMock = vi.mocked(listEntitlementsByValue)
const getAccountSchemaMock = vi.mocked(getAccountSchema)
const underlyingAccountsByIdentity = new Map<string, Array<{ sourceId: string; attributes: Record<string, unknown> }>>()
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

function stubInboundSchema(schema: { configuration?: Record<string, unknown>; attributes?: Array<{ name: string }> }) {
    getAccountSchemaMock.mockImplementation(async (_sources, sourceId: string) => {
        if (sourceId === 'source-123') {
            return RESULT_SOURCE_SCHEMA
        }
        return schema
    })
}

describe('custom:machine-identity-entitlements', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        createAccountV1.mockReset()
        listAccountsV1.mockReset()
        listMachineIdentitiesMock.mockReset()
        resolveMachineIdentityMock.mockReset()
        listEntitlementsByValueMock.mockReset()
        getAccountSchemaMock.mockReset()
        getAccountSchemaMock.mockImplementation(async (_sources, sourceId: string) => {
            if (sourceId === 'source-123') {
                return RESULT_SOURCE_SCHEMA
            }
            return {
                configuration: { inboundEntitlements: 'appRole' },
                attributes: [{ name: 'appRole' }],
            }
        })
        underlyingAccountsByIdentity.clear()
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
        listMachineIdentitiesMock.mockResolvedValue([
            { id: 'mi-1', cisIdentityId: 'cis-1', userEntitlements: [] },
            { id: 'mi-2', cisIdentityId: 'cis-2', userEntitlements: [] },
        ])
        underlyingAccountsByIdentity.set('cis-1', [{ sourceId: 'src-1', attributes: { appRole: 'CN=Admins' } }])
        underlyingAccountsByIdentity.set('cis-2', [{ sourceId: 'src-1', attributes: { appRole: 'CN=A' } }])
        stubInboundSchema({
            configuration: { inboundEntitlements: 'appRole' },
            attributes: [{ name: 'appRole' }],
        })
        listEntitlementsByValueMock.mockImplementation(async (_client, value) => {
            if (value === 'CN=Admins') {
                return [{ id: 'ent-1', sourceId: 'src-1', value }]
            }
            return [{ id: 'ent-2', sourceId: 'src-1', value }]
        })

        const res = await invokeConnected({ requestId: 'req-scan' })

        expect(listMachineIdentitiesMock).toHaveBeenCalled()
        expect(resolveMachineIdentityMock).not.toHaveBeenCalled()
        expect([...persistedAccounts.keys()].sort()).toEqual(['req-scan:mi-1', 'req-scan:mi-2'])
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 'success',
                responses: expect.arrayContaining(['req-scan:mi-1', 'req-scan:mi-2']),
            })
        )
    })

    it('Empty delta skips persist', async () => {
        listMachineIdentitiesMock.mockResolvedValue([
            {
                id: 'mi-1',
                userEntitlements: [{ sourceId: 'src-1', entitlementId: 'ent-1' }],
            },
        ])
        underlyingAccountsByIdentity.set('mi-1', [{ sourceId: 'src-1', attributes: { appRole: 'CN=Admins' } }])
        stubInboundSchema({
            configuration: { inboundEntitlements: 'appRole' },
            attributes: [{ name: 'appRole' }],
        })
        listEntitlementsByValueMock.mockResolvedValue([{ id: 'ent-1', sourceId: 'src-1', value: 'CN=Admins' }])

        const res = await invokeConnected({ requestId: 'req-empty-delta' })

        expect(persistedAccounts.size).toBe(0)
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({ status: 'success', responses: [] }))
    })

    it('Tenant scan with no work succeeds', async () => {
        listMachineIdentitiesMock.mockResolvedValue([{ id: 'mi-1', userEntitlements: [] }])

        const res = await invokeConnected({ requestId: 'req-no-work' })

        expect(persistedAccounts.size).toBe(0)
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({ status: 'success' }))
    })

    it('Targeted unknown identity rejected', async () => {
        resolveMachineIdentityMock.mockResolvedValue(undefined)
        const res = await invokeConnected({ requestId: 'req-unknown', identityId: 'missing' })

        expect(listMachineIdentitiesMock).not.toHaveBeenCalled()
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
            cisIdentityId: 'cis-1',
            userEntitlements: [],
        })
        underlyingAccountsByIdentity.set('cis-1', [{ sourceId: 'src-1', attributes: { appRole: 'CN=Admins' } }])
        stubInboundSchema({
            configuration: { inboundEntitlements: 'appRole' },
            attributes: [{ name: 'appRole' }],
        })
        listEntitlementsByValueMock.mockResolvedValue([{ id: 'ent-1', sourceId: 'src-1' }])

        await invokeConnected({ requestId: 'req-one', identityId: 'cis-1' })

        expect(resolveMachineIdentityMock).toHaveBeenCalledWith(expect.anything(), 'cis-1')
        expect(listMachineIdentitiesMock).not.toHaveBeenCalled()
        expect(listAccountsV1).toHaveBeenCalledWith(expect.objectContaining({ filters: 'identityId eq "cis-1"' }))
        expect([...persistedAccounts.keys()]).toEqual(['req-one:mi-1'])
    })

    it('Values union across processable accounts', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', cisIdentityId: 'cis-1', userEntitlements: [] })
        underlyingAccountsByIdentity.set('cis-1', [
            { sourceId: 'src-1', attributes: { appRole: 'CN=A' } },
            { sourceId: 'src-2', attributes: { appRole: 'CN=B' } },
        ])
        stubInboundSchema({
            configuration: { inboundEntitlements: 'appRole' },
            attributes: [{ name: 'appRole' }],
        })
        listEntitlementsByValueMock.mockImplementation(async (_client, value) => [
            { id: value === 'CN=A' ? 'ent-a' : 'ent-b', sourceId: 'src-1', value },
        ])

        await invokeConnected({ requestId: 'req-union', identityId: 'mi-1' })

        expect(persistedAccounts.get('req-union:mi-1')?.['machine-identity-entitlements:entitlement-ids']).toEqual(
            expect.arrayContaining(['ent-a', 'ent-b'])
        )
    })

    it('Unmatched value is skipped', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        underlyingAccountsByIdentity.set('mi-1', [
            { sourceId: 'src-1', attributes: { groups: ['CN=Admins', 'no-such-entitlement'] } },
        ])
        stubInboundSchema({
            configuration: { inboundEntitlements: 'groups' },
            attributes: [{ name: 'groups' }],
        })
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
        underlyingAccountsByIdentity.set('mi-1', [{ sourceId: 'src-1', attributes: { groups: ['CN=A', 'CN=B'] } }])
        stubInboundSchema({
            configuration: { inboundEntitlements: 'groups' },
            attributes: [{ name: 'groups' }],
        })
        listEntitlementsByValueMock.mockImplementation(async (_client, value) => [
            {
                id: value === 'CN=A' ? 'ent-a' : 'ent-b',
                sourceId: value === 'CN=A' ? 'src-1' : 'src-2',
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
        expect(ids[0] === 'ent-a' ? sources[0] : sources[1]).toBe('src-1')
        expect(account?.operationName).toBe('custom:machine-identity-entitlements')
    })

    it('Schema without inboundEntitlements is skipped during invoke', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        underlyingAccountsByIdentity.set('mi-1', [{ sourceId: 'src-1', attributes: { appRole: 'CN=Admins' } }])
        stubInboundSchema({ attributes: [{ name: 'appRole' }] })

        const res = await invokeConnected({ requestId: 'req-skip-schema', identityId: 'mi-1' })

        expect(listEntitlementsByValueMock).not.toHaveBeenCalled()
        expect(persistedAccounts.size).toBe(0)
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({ status: 'success' }))
    })

    it('Unknown attribute name is skipped during invoke', async () => {
        resolveMachineIdentityMock.mockResolvedValue({ id: 'mi-1', userEntitlements: [] })
        underlyingAccountsByIdentity.set('mi-1', [{ sourceId: 'src-1', attributes: { appRole: 'CN=Admins' } }])
        stubInboundSchema({
            configuration: { inboundEntitlements: 'groups' },
            attributes: [{ name: 'appRole' }],
        })

        await invokeConnected({ requestId: 'req-skip-attr', identityId: 'mi-1' })

        expect(listEntitlementsByValueMock).not.toHaveBeenCalled()
        expect(persistedAccounts.size).toBe(0)
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

            expect(listMachineIdentitiesMock).not.toHaveBeenCalled()
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
        expect(readme).toContain('inboundEntitlements')
        expect(readme).toMatch(/workflow/i)
        expect(readme).toMatch(/scope/i)
        expect(readme).toContain('identityId eq')
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
