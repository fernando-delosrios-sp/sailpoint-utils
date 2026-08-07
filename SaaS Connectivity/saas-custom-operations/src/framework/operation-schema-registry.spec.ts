import { describe, expect, it } from 'vitest'
import { defineOperationSchema } from './define-operation-schema'
import {
    clearOperationSchemaRegistry,
    getOperationSchema,
    registerOperationSchema,
} from './operation-schema-registry'

describe('operation-schema-registry', () => {
    it('stores and retrieves schemas by command name', () => {
        clearOperationSchemaRegistry()
        const schema = defineOperationSchema({ summary: 'string' }, { command: 'custom:example' })
        registerOperationSchema('custom:example', schema)

        expect(getOperationSchema('custom:example')).toBe(schema)
        expect(getOperationSchema('custom:missing')).toBeUndefined()
    })
})
