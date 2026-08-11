import { SourcesApi } from 'sailpoint-api-client'
import { describe, expect, it, vi } from 'vitest'
import {
    createAccountSchema,
    createSource,
    findSourceByName,
    getAccountSchema,
    patchAccountSchema,
} from './source-client'

describe('isc/sources source-client', () => {
    it('findSourceByName lists sources with a name filter', async () => {
        const listSourcesV1 = vi.fn().mockResolvedValue({ data: [{ id: 'source-1', name: 'Results Store' }] })
        const sourcesApi = { listSourcesV1 } as unknown as SourcesApi

        const source = await findSourceByName(sourcesApi, 'Results Store')

        expect(listSourcesV1).toHaveBeenCalledWith({ filters: 'name eq "Results Store"' })
        expect(source?.id).toBe('source-1')
    })

    it('createSource invokes createSourceV1 with caller payload', async () => {
        const createSourceV1 = vi.fn().mockResolvedValue({ data: { id: 'new-source-id' } })
        const sourcesApi = { createSourceV1 } as unknown as SourcesApi

        const sourceId = await createSource(
            sourcesApi,
            {
                name: 'Custom Source',
                type: 'DelimitedFile',
                owner: { type: 'IDENTITY', id: 'owner-1' },
            },
            { provisionAsCsv: true }
        )

        expect(createSourceV1).toHaveBeenCalledWith(
            expect.objectContaining({
                source: expect.objectContaining({ name: 'Custom Source' }),
                provisionAsCsv: true,
            })
        )
        expect(sourceId).toBe('new-source-id')
    })

    it('getAccountSchema returns the account schema entry', async () => {
        const getSourceSchemasV1 = vi.fn().mockResolvedValue({
            data: [
                { id: 'schema-1', name: 'account', attributes: [] },
                { id: 'schema-2', name: 'group', attributes: [] },
            ],
        })
        const sourcesApi = { getSourceSchemasV1 } as unknown as SourcesApi

        const schema = await getAccountSchema(sourcesApi, 'source-1')

        expect(schema?.id).toBe('schema-1')
    })

    it('createAccountSchema invokes createSourceSchemaV1', async () => {
        const createSourceSchemaV1 = vi.fn().mockResolvedValue({ data: { id: 'schema-new', name: 'account' } })
        const sourcesApi = { createSourceSchemaV1 } as unknown as SourcesApi

        const schema = await createAccountSchema(sourcesApi, 'source-1', { name: 'account', attributes: [] })

        expect(createSourceSchemaV1).toHaveBeenCalled()
        expect(schema.id).toBe('schema-new')
    })

    it('patchAccountSchema invokes updateSourceSchemaV1 when patches are present', async () => {
        const updateSourceSchemaV1 = vi.fn().mockResolvedValue({})
        const sourcesApi = { updateSourceSchemaV1 } as unknown as SourcesApi

        await patchAccountSchema(sourcesApi, 'source-1', 'schema-1', [{ op: 'add', path: '/attributes/-', value: {} }])

        expect(updateSourceSchemaV1).toHaveBeenCalled()
    })
})
