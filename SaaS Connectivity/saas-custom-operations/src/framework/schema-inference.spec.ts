import { describe, expect, it } from 'vitest'
import { inferFromTsType, inferSchemaAttribute } from './schema-inference'

describe('inferFromTsType', () => {
    it('maps string to STRING isMulti false', () => {
        expect(inferFromTsType('string')).toEqual({ type: 'STRING', isMulti: false })
    })

    it('maps number to INT isMulti false', () => {
        expect(inferFromTsType('number')).toEqual({ type: 'INT', isMulti: false })
    })

    it('maps boolean to BOOLEAN isMulti false', () => {
        expect(inferFromTsType('boolean')).toEqual({ type: 'BOOLEAN', isMulti: false })
    })

    it('maps bigint to LONG isMulti false', () => {
        expect(inferFromTsType('bigint')).toEqual({ type: 'LONG', isMulti: false })
    })

    it('maps Date to DATE isMulti false', () => {
        expect(inferFromTsType('Date')).toEqual({ type: 'DATE', isMulti: false })
    })

    it('maps object to STRING isMulti false', () => {
        expect(inferFromTsType('object')).toEqual({ type: 'STRING', isMulti: false })
    })

    it('maps Record types to STRING isMulti false', () => {
        expect(inferFromTsType('Record<string, unknown>')).toEqual({ type: 'STRING', isMulti: false })
    })

    it('maps string[] to STRING isMulti true', () => {
        expect(inferFromTsType('string[]')).toEqual({ type: 'STRING', isMulti: true })
    })

    it('maps Array<number> to INT isMulti true', () => {
        expect(inferFromTsType('Array<number>')).toEqual({ type: 'INT', isMulti: true })
    })
})

describe('inferSchemaAttribute', () => {
    it('maps number field to INT', () => {
        expect(inferSchemaAttribute({ name: 'count', type: 'number', optional: false })).toEqual({
            name: 'count',
            type: 'INT',
            isMulti: false,
        })
    })

    it('maps string[] field to STRING isMulti true', () => {
        expect(inferSchemaAttribute({ name: 'tags', type: 'string[]', optional: false })).toEqual({
            name: 'tags',
            type: 'STRING',
            isMulti: true,
        })
    })
})
