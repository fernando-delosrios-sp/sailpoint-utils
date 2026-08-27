import { describe, expect, it } from 'vitest'
import { buildBaseAccountSchema, collectBaseSchemaAttributes } from './base-account-schema'

describe('collectBaseSchemaAttributes', () => {
    it('includes core attributes and merges operation output fields', () => {
        const attrs = collectBaseSchemaAttributes([
            { name: 'summary', type: 'string' },
            { name: 'step', type: 'string' },
        ])

        expect([...attrs.keys()].sort()).toEqual(['date', 'details', 'id', 'operationName', 'status', 'step', 'summary'])
    })

    it('excludes reserved framework keys', () => {
        const attrs = collectBaseSchemaAttributes([{ name: 'sourceId', type: 'string' }])

        expect(attrs.has('sourceId')).toBe(false)
    })

    it('merges isMulti when the same field appears in multiple operations', () => {
        const attrs = collectBaseSchemaAttributes([
            { name: 'tags', type: 'string' },
            { name: 'tags', type: 'string[]' },
        ])

        expect(attrs.get('tags')).toEqual({ name: 'tags', type: 'STRING', isMulti: true })
    })
})

describe('buildBaseAccountSchema', () => {
    it('returns account schema with core metadata and sorted dynamic attributes', () => {
        const schema = buildBaseAccountSchema([
            { name: 'summary', type: 'string' },
            { name: 'count', type: 'number' },
        ])

        expect(schema.name).toBe('account')
        expect(schema.identityAttribute).toBe('id')
        expect(schema.displayAttribute).toBe('id')
        expect(schema.nativeObjectType).toBe('User')
        expect(schema.attributes?.map((attr) => attr.name)).toEqual([
            'id',
            'status',
            'date',
            'details',
            'operationName',
            'count',
            'summary',
        ])
        expect(schema.attributes?.find((attr) => attr.name === 'details')).toEqual(
            expect.objectContaining({ type: 'STRING', isMulti: false })
        )
        expect(schema.attributes?.find((attr) => attr.name === 'count')).toEqual(
            expect.objectContaining({ type: 'INT', isMulti: false })
        )
    })
})
