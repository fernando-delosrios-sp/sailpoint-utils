import { ConnectorError } from '@sailpoint/connector-sdk'
import { SourcesApi } from 'sailpoint-api-client'
import { describe, expect, it, vi } from 'vitest'
import {
    createDelimitedFileSource,
    ensureSourceSchema,
    resolveSourceByName,
    resolveTokenIdentity,
} from './source-provisioning'

function createMockJwt(payload: Record<string, unknown>): string {
    const header = Buffer.from(JSON.stringify({ alg: 'none' })).toString('base64url')
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url')
    return `${header}.${body}.signature`
}

describe('resolveTokenIdentity', () => {
    it('extracts identity_id from JWT payload', () => {
        const token = createMockJwt({ identity_id: 'abc-123', sub: 'other' })
        expect(resolveTokenIdentity(token)).toBe('abc-123')
    })

    it('falls back to sub when identity_id is absent', () => {
        const token = createMockJwt({ sub: 'identity-sub' })
        expect(resolveTokenIdentity(token)).toBe('identity-sub')
    })

    it('throws when token cannot be decoded', () => {
        expect(() => resolveTokenIdentity('not-a-jwt')).toThrow(ConnectorError)
    })
})

describe('resolveSourceByName', () => {
    it('returns existing source ID when found by name', async () => {
        const sourcesApi = {
            listSourcesV1: vi.fn().mockResolvedValue({ data: [{ id: 'existing-id', name: 'Results Store' }] }),
            createSourceV1: vi.fn(),
        } as unknown as SourcesApi

        const sourceId = await resolveSourceByName(sourcesApi, 'Results Store', 'token')

        expect(sourceId).toBe('existing-id')
        expect(sourcesApi.createSourceV1).not.toHaveBeenCalled()
    })

    it('creates DelimitedFile source when name not found', async () => {
        const token = createMockJwt({ identity_id: 'owner-id' })
        const sourcesApi = {
            listSourcesV1: vi
                .fn()
                .mockResolvedValueOnce({ data: [] })
                .mockResolvedValueOnce({ data: [] }),
            createSourceV1: vi.fn().mockResolvedValue({ data: { id: 'new-source-id' } }),
            createSourceSchemaV1: vi.fn().mockResolvedValue({ data: { id: 'schema-id', name: 'account' } }),
        } as unknown as SourcesApi

        const sourceId = await createDelimitedFileSource(sourcesApi, 'Results Store', 'owner-id')

        expect(sourceId).toBe('new-source-id')
        expect(sourcesApi.createSourceV1).toHaveBeenCalledWith(
            expect.objectContaining({
                source: expect.objectContaining({
                    name: 'Results Store',
                    type: 'DelimitedFile',
                    connector: 'delimited-file-angularsc',
                    connectorClass: 'sailpoint.connector.delimitedfile.DelimitedFileConnector',
                    connectorScriptName: 'delimited-file-angularsc',
                    provisionAsCsv: true,
                    owner: { type: 'IDENTITY', id: 'owner-id' },
                }),
                provisionAsCsv: true,
            })
        )
        expect(sourcesApi.createSourceSchemaV1).toHaveBeenCalled()
    })

    it('re-lists source on concurrent create conflict', async () => {
        const token = createMockJwt({ identity_id: 'owner-id' })
        const sourcesApi = {
            listSourcesV1: vi
                .fn()
                .mockResolvedValueOnce({ data: [] })
                .mockResolvedValueOnce({ data: [{ id: 'race-winner', name: 'Results Store' }] }),
            createSourceV1: vi.fn().mockRejectedValue(new Error('conflict')),
            createSourceSchemaV1: vi.fn(),
        } as unknown as SourcesApi

        const sourceId = await resolveSourceByName(sourcesApi, 'Results Store', token)

        expect(sourceId).toBe('race-winner')
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

    it('patches isMulti to true on conflict', async () => {
        const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const sourcesApi = {
            getSourceSchemasV1: vi.fn().mockResolvedValue({
                data: [
                    {
                        id: 'schema-1',
                        name: 'account',
                        attributes: [
                            { name: 'id', type: 'STRING', isMulti: false },
                            { name: 'status', type: 'STRING', isMulti: false },
                            { name: 'date', type: 'STRING', isMulti: false },
                            { name: 'tags', type: 'STRING', isMulti: false },
                        ],
                    },
                ],
            }),
            updateSourceSchemaV1: vi.fn().mockResolvedValue({}),
            createSourceSchemaV1: vi.fn(),
        } as unknown as SourcesApi

        await ensureSourceSchema(sourcesApi, 'source-1', [{ name: 'tags', type: 'string[]' }], ['tags'])

        expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('isMulti conflict for tags'))
        expect(sourcesApi.updateSourceSchemaV1).toHaveBeenCalledWith(
            expect.objectContaining({
                jsonPatchOperation: [expect.objectContaining({ op: 'replace', path: '/attributes/3/isMulti', value: true })],
            })
        )
        warnSpy.mockRestore()
    })
})
