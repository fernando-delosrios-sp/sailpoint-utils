import { SourcesApi } from 'sailpoint-api-client'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { defineOperationSchema } from './define-operation-schema'
import {
    clearOperationSchemaRegistry,
    registerOperationSchema,
} from './operation-schema-registry'
import {
    applyBaseAccountSchema,
    createDelimitedFileResultSource,
    ensureSourceSchema,
    resolveSourceByName,
} from './result-source'

function createMockJwt(payload: Record<string, unknown>): string {
    const header = Buffer.from(JSON.stringify({ alg: 'none' })).toString('base64url')
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url')
    return `${header}.${body}.signature`
}

afterEach(() => {
    clearOperationSchemaRegistry()
})

describe('resolveSourceByName', () => {
    it('returns existing source ID when found by name', async () => {
        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({
                data: [{ id: 'existing-id', name: 'Results Store', type: 'DelimitedFile' }],
            }),
            createSourceV1: vi.fn(),
        } as unknown as SourcesApi

        const sourceId = await resolveSourceByName(sourcesApi, 'Results Store', 'token')

        expect(sourceId).toBe('existing-id')
        expect(sourcesApi.createSourceV1).not.toHaveBeenCalled()
    })

    it('creates DelimitedFile result source when name not found', async () => {
        const sourcesApi = {
            listSourcesV1: vi
                .fn()
                .mockResolvedValueOnce({ data: [] })
                .mockResolvedValueOnce({ data: [] }),
            createSourceV1: vi.fn().mockResolvedValue({ data: { id: 'new-source-id' } }),
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-id', name: 'account' } }),
        } as unknown as SourcesApi

        const sourceId = await createDelimitedFileResultSource(sourcesApi, 'Results Store', 'owner-id')

        expect(sourceId).toBe('new-source-id')
        expect(sourcesApi.createSourceV1).toHaveBeenCalled()
        expect(sourcesApi.createSourceSchemaV1).toHaveBeenCalled()
    })

    it('creates base schema with invoking operation output fields only', async () => {
        registerOperationSchema(
            'custom:other',
            defineOperationSchema({ violationId: 'string' }, { command: 'custom:other' })
        )

        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceV1: vi.fn().mockResolvedValue({ data: { id: 'new-source-id' } }),
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-id', name: 'account' } }),
        } as unknown as SourcesApi

        await createDelimitedFileResultSource(sourcesApi, 'Results Store', 'owner-id', [
            { name: 'summary', type: 'string' },
            { name: 'step', type: 'string' },
        ])

        expect(sourcesApi.createSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                sourceId: 'new-source-id',
                schema: expect.objectContaining({
                    identityAttribute: 'id',
                    attributes: expect.arrayContaining([
                        expect.objectContaining({ name: 'summary', type: 'STRING' }),
                        expect.objectContaining({ name: 'step', type: 'STRING' }),
                    ]),
                }),
            })
        )

        const createCall = (sourcesApi.createSourceSchemaV1 as ReturnType<typeof vi.fn>).mock.calls[0]?.[0]
        const attributeNames = createCall.schema.attributes.map((attr: { name: string }) => attr.name)
        expect(attributeNames).not.toContain('violationId')
    })

    it('creates core-only base schema when outputFields is empty', async () => {
        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceV1: vi.fn().mockResolvedValue({ data: { id: 'new-source-id' } }),
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-id', name: 'account' } }),
        } as unknown as SourcesApi

        await createDelimitedFileResultSource(sourcesApi, 'Results Store', 'owner-id', [])

        const createCall = (sourcesApi.createSourceSchemaV1 as ReturnType<typeof vi.fn>).mock.calls[0]?.[0]
        const attributeNames = createCall.schema.attributes.map((attr: { name: string }) => attr.name)
        expect(attributeNames).toEqual(['id', 'status', 'date', 'details', 'operationName'])
    })

    it('rejects non-DelimitedFile source with the same name', async () => {
        const token = createMockJwt({ identity_id: 'owner-id' })
        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({
                data: [{ id: 'connector-id', name: 'SaaS Custom Operations', type: 'Web Services' }],
            }),
            createSourceV1: vi.fn(),
        } as unknown as SourcesApi

        await expect(resolveSourceByName(sourcesApi, 'SaaS Custom Operations', token)).rejects.toThrow(/DelimitedFile/)
        expect(sourcesApi.createSourceV1).not.toHaveBeenCalled()
    })

    it('re-lists source on concurrent create conflict', async () => {
        const token = createMockJwt({ identity_id: 'owner-id' })
        const sourcesApi = {
            listSourcesV1: vi
                .fn()
                .mockResolvedValueOnce({ data: [] })
                .mockResolvedValueOnce({ data: [{ id: 'race-winner', name: 'Results Store', type: 'DelimitedFile' }] }),
            createSourceV1: vi.fn().mockRejectedValue(new Error('conflict')),
            createSourceSchemaV1: vi.fn(),
        } as unknown as SourcesApi

        const sourceId = await resolveSourceByName(sourcesApi, 'Results Store', token)

        expect(sourceId).toBe('race-winner')
    })
})

describe('applyBaseAccountSchema', () => {
    it('replaces a discovered schema with the base schema attributes', async () => {
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({
                data: [
                    {
                        id: 'schema-1',
                        name: 'account',
                        identityAttribute: 'nativeId',
                        displayAttribute: 'nativeId',
                        nativeObjectType: 'Account',
                        attributes: [{ name: 'nativeId', type: 'STRING', isMulti: false }],
                    },
                ],
            }),
            createSourceSchemaV1: vi.fn(),
            updateSourceSchemaV1: vi.fn().mockResolvedValue({}),
        } as unknown as SourcesApi

        await applyBaseAccountSchema(sourcesApi, 'source-1', [{ name: 'summary', type: 'string' }])

        expect(sourcesApi.createSourceSchemaV1).not.toHaveBeenCalled()
        expect(sourcesApi.updateSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                sourceId: 'source-1',
                schemaId: 'schema-1',
                jsonPatchOperation: expect.arrayContaining([
                    expect.objectContaining({ op: 'replace', path: '/identityAttribute', value: 'id' }),
                    expect.objectContaining({
                        op: 'replace',
                        path: '/attributes',
                        value: expect.arrayContaining([
                            expect.objectContaining({ name: 'id', type: 'STRING' }),
                            expect.objectContaining({ name: 'summary', type: 'STRING' }),
                        ]),
                    }),
                ]),
            })
        )

        const patchCall = (sourcesApi.updateSourceSchemaV1 as ReturnType<typeof vi.fn>).mock.calls[0]?.[0]
        const attributesPatch = patchCall.jsonPatchOperation.find(
            (op: { path?: string }) => op.path === '/attributes'
        )
        const attributeNames = attributesPatch.value.map((attr: { name: string }) => attr.name)
        expect(attributeNames).not.toContain('nativeId')
    })

    it('excludes reserved framework keys from the base schema', async () => {
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-id', name: 'account' } }),
        } as unknown as SourcesApi

        await applyBaseAccountSchema(sourcesApi, 'source-1', [
            { name: 'sourceId', type: 'string' },
            { name: 'summary', type: 'string' },
        ])
    })

    it('replaces conflicting attribute types during base apply', async () => {
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({
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
                            { name: 'details', type: 'STRING', isMulti: false },
                            { name: 'operationName', type: 'STRING', isMulti: false },
                            { name: 'count', type: 'STRING', isMulti: false },
                        ],
                    },
                ],
            }),
            createSourceSchemaV1: vi.fn(),
            updateSourceSchemaV1: vi.fn().mockResolvedValue({}),
        } as unknown as SourcesApi

        await applyBaseAccountSchema(sourcesApi, 'source-1', [{ name: 'count', type: 'number' }])
    })
})

describe('ensureSourceSchema', () => {
    it('adds later operation output fields when schema only has prior operation attrs', async () => {
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({
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
                            { name: 'details', type: 'STRING', isMulti: false },
                            { name: 'operationName', type: 'STRING', isMulti: false },
                            { name: 'summary', type: 'STRING', isMulti: false },
                        ],
                    },
                ],
            }),
            updateSourceSchemaV1: vi.fn().mockResolvedValue({}),
            createSourceSchemaV1: vi.fn(),
        } as unknown as SourcesApi

        await ensureSourceSchema(
            sourcesApi,
            'source-1',
            [{ name: 'violationId', type: 'string' }],
            ['violationId']
        )

        expect(sourcesApi.updateSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                jsonPatchOperation: expect.arrayContaining([
                    expect.objectContaining({
                        op: 'replace',
                        path: '/attributes',
                        value: expect.arrayContaining([
                            expect.objectContaining({ name: 'violationId', type: 'STRING', isMulti: false }),
                        ]),
                    }),
                ]),
            })
        )
    })

    it('adds missing operationName core attribute to existing schema', async () => {
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({
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
                            { name: 'details', type: 'STRING', isMulti: false },
                        ],
                    },
                ],
            }),
            updateSourceSchemaV1: vi.fn().mockResolvedValue({}),
            createSourceSchemaV1: vi.fn(),
        } as unknown as SourcesApi

        await ensureSourceSchema(sourcesApi, 'source-1', [{ name: 'summary', type: 'string' }], ['summary'])

        expect(sourcesApi.updateSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                sourceId: 'source-1',
                schemaId: 'schema-1',
                jsonPatchOperation: expect.arrayContaining([
                    expect.objectContaining({
                        op: 'replace',
                        path: '/attributes',
                        value: expect.arrayContaining([
                            expect.objectContaining({ name: 'operationName', type: 'STRING', isMulti: false }),
                            expect.objectContaining({ name: 'summary', type: 'STRING', isMulti: false }),
                        ]),
                    }),
                ]),
            })
        )
    })

    it('adds missing output attribute to schema', async () => {
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({
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
                            { name: 'details', type: 'STRING', isMulti: false },
                            { name: 'operationName', type: 'STRING', isMulti: false },
                        ],
                    },
                ],
            }),
            updateSourceSchemaV1: vi.fn().mockResolvedValue({}),
            createSourceSchemaV1: vi.fn(),
        } as unknown as SourcesApi

        await ensureSourceSchema(sourcesApi, 'source-1', [{ name: 'summary', type: 'string' }], ['summary'])

        expect(sourcesApi.updateSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                sourceId: 'source-1',
                schemaId: 'schema-1',
                jsonPatchOperation: expect.arrayContaining([
                    expect.objectContaining({
                        op: 'replace',
                        path: '/attributes',
                        value: expect.arrayContaining([
                            expect.objectContaining({ name: 'summary', type: 'STRING', isMulti: false }),
                        ]),
                    }),
                ]),
            })
        )
    })

    it('creates schema with operation output fields when schema is missing', async () => {
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-1', name: 'account' } }),
            updateSourceSchemaV1: vi.fn(),
        } as unknown as SourcesApi

        await ensureSourceSchema(sourcesApi, 'source-1', [{ name: 'summary', type: 'string' }], ['summary'])

        expect(sourcesApi.createSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                sourceId: 'source-1',
                schema: expect.objectContaining({
                    attributes: expect.arrayContaining([
                        expect.objectContaining({ name: 'id', type: 'STRING' }),
                        expect.objectContaining({ name: 'summary', type: 'STRING' }),
                    ]),
                }),
            })
        )
        expect(sourcesApi.updateSourceSchemaV1).not.toHaveBeenCalled()
    })

    it('warns on type conflict and keeps existing attribute', async () => {
        const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({
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
                            { name: 'details', type: 'STRING', isMulti: false },
                            { name: 'operationName', type: 'STRING', isMulti: false },
                            { name: 'count', type: 'STRING', isMulti: false },
                        ],
                    },
                ],
            }),
            updateSourceSchemaV1: vi.fn(),
            createSourceSchemaV1: vi.fn(),
        } as unknown as SourcesApi

        await ensureSourceSchema(sourcesApi, 'source-1', [{ name: 'count', type: 'number' }], ['count'])

        expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('Type conflict for count'))
        expect(sourcesApi.updateSourceSchemaV1).not.toHaveBeenCalled()
        warnSpy.mockRestore()
    })

    it('continues persist when schema patch returns HTTP 404', async () => {
        const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({
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
                            { name: 'details', type: 'STRING', isMulti: false },
                            { name: 'operationName', type: 'STRING', isMulti: false },
                        ],
                    },
                ],
            }),
            updateSourceSchemaV1: vi.fn().mockRejectedValue({ response: { status: 404 } }),
            createSourceSchemaV1: vi.fn(),
        } as unknown as SourcesApi

        await ensureSourceSchema(sourcesApi, 'source-1', [{ name: 'summary', type: 'string' }], ['summary'])

        expect(warnSpy).toHaveBeenCalledWith(
            expect.stringContaining('account schema patch unavailable for source source-1 (404)')
        )
        warnSpy.mockRestore()
    })
})
