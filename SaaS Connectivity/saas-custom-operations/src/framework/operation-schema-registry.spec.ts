import { describe, expect, it } from 'vitest'
import { defineOperationSchema } from './define-operation-schema'
import {
    clearOperationSchemaRegistry,
    getOperationSchema,
    listRegisteredOperationSchemas,
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

    it('lists all registered schemas', () => {
        clearOperationSchemaRegistry()
        const example = defineOperationSchema({ summary: 'string' }, { command: 'custom:example' })
        const sod = defineOperationSchema({ violationId: 'string' }, { command: 'custom:sod-remediation' })
        registerOperationSchema('custom:example', example)
        registerOperationSchema('custom:sod-remediation', sod)

        const listed = listRegisteredOperationSchemas()
        expect(listed).toHaveLength(2)
        expect(listed).toContain(example)
        expect(listed).toContain(sod)
    })
})
