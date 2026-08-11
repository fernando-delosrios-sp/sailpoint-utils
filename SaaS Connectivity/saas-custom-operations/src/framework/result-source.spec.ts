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

    it('creates base schema with registered operation output fields', async () => {
        registerOperationSchema(
            'custom:example',
            defineOperationSchema({ summary: 'string', step: 'string' }, { command: 'custom:example' })
        )

        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceV1: vi.fn().mockResolvedValue({ data: { id: 'new-source-id' } }),
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-id', name: 'account' } }),
        } as unknown as SourcesApi

        await createDelimitedFileResultSource(sourcesApi, 'Results Store', 'owner-id')

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
    it('patches an existing discovered schema instead of creating a duplicate', async () => {
        registerOperationSchema(
            'custom:example',
            defineOperationSchema({ summary: 'string' }, { command: 'custom:example' })
        )

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

        await applyBaseAccountSchema(sourcesApi, 'source-1')

        expect(sourcesApi.createSourceSchemaV1).not.toHaveBeenCalled()
        expect(sourcesApi.updateSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                sourceId: 'source-1',
                schemaId: 'schema-1',
                jsonPatchOperation: expect.arrayContaining([
                    expect.objectContaining({ op: 'replace', path: '/identityAttribute', value: 'id' }),
                    expect.objectContaining({
                        op: 'add',
                        path: '/attributes/-',
                        value: expect.objectContaining({ name: 'summary', type: 'STRING' }),
                    }),
                ]),
            })
        )
    })

    it('excludes reserved framework keys from the base schema', async () => {
        registerOperationSchema(
            'custom:example',
            defineOperationSchema({ sourceId: 'string', summary: 'string' }, { command: 'custom:example' })
        )

        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({ data: [] }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-id', name: 'account' } }),
        } as unknown as SourcesApi

        await applyBaseAccountSchema(sourcesApi, 'source-1')

        const createCall = (sourcesApi.createSourceSchemaV1 as ReturnType<typeof vi.fn>).mock.calls[0]?.[0]
        const attributeNames = createCall.schema.attributes.map((attr: { name: string }) => attr.name)
        expect(attributeNames).toContain('summary')
        expect(attributeNames).not.toContain('sourceId')
    })

    it('warns on type conflict during base apply and keeps existing attribute', async () => {
        const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
        registerOperationSchema(
            'custom:typed',
            defineOperationSchema({ count: 'number' }, { command: 'custom:typed' })
        )

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
                            { name: 'count', type: 'STRING', isMulti: false },
                        ],
                    },
                ],
            }),
            createSourceSchemaV1: vi.fn(),
            updateSourceSchemaV1: vi.fn().mockResolvedValue({}),
        } as unknown as SourcesApi

        await applyBaseAccountSchema(sourcesApi, 'source-1')

        expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('Type conflict for count'))
        if ((sourcesApi.updateSourceSchemaV1 as ReturnType<typeof vi.fn>).mock.calls.length > 0) {
            const patchCall = (sourcesApi.updateSourceSchemaV1 as ReturnType<typeof vi.fn>).mock.calls[0]?.[0]
            const attributePatches = patchCall.jsonPatchOperation.filter(
                (op: { path?: string }) => op.path?.startsWith('/attributes/')
            )
            expect(attributePatches.every((op: { value?: { name?: string } }) => op.value?.name !== 'count')).toBe(true)
        }
        warnSpy.mockRestore()
    })
})

describe('ensureSourceSchema', () => {
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
                        op: 'add',
                        path: '/attributes/-',
                        value: expect.objectContaining({ name: 'summary', type: 'STRING', isMulti: false }),
                    }),
                ]),
            })
        )
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
