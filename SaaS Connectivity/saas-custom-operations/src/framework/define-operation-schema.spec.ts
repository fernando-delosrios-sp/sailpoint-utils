import { describe, expect, it } from 'vitest'
import { defineOperationSchema } from './define-operation-schema'

describe('defineOperationSchema', () => {
    it('maps string specs to output fields', () => {
        expect(defineOperationSchema({ summary: 'string', count: 'number' })).toEqual({
            command: undefined,
            outputFields: [
                { name: 'count', type: 'number', optional: false },
                { name: 'summary', type: 'string', optional: false },
            ],
        })
    })

    it('supports optional field metadata', () => {
        expect(defineOperationSchema({ summary: 'string', step: { type: 'string', optional: true } })).toEqual({
            command: undefined,
            outputFields: [
                { name: 'step', type: 'string', optional: true },
                { name: 'summary', type: 'string', optional: false },
            ],
        })
    })

    it('accepts an optional command name', () => {
        expect(defineOperationSchema({ summary: 'string' }, { command: 'custom:example' })).toEqual({
            command: 'custom:example',
            outputFields: [{ name: 'summary', type: 'string', optional: false }],
        })
    })
})
