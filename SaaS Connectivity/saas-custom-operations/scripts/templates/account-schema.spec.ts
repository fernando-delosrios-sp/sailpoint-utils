import { describe, expect, it } from 'vitest'
import { buildAccountSchema } from './account-schema'
import { OperationMeta } from './types'

const exampleOp: OperationMeta = {
    command: 'custom:example',
    modulePath: '/fake/example-operation.ts',
    input: [{ name: 'message', optional: true, type: 'string' }],
    output: [
        { name: 'summary', optional: false, type: 'string' },
        { name: 'step', optional: true, type: 'string' },
        { name: 'sourceId', optional: false, type: 'string' },
    ],
    childIdentities: [],
}

const unregisteredOp: OperationMeta = {
    command: 'custom:unregistered',
    modulePath: '/fake/unregistered.ts',
    input: [],
    output: [{ name: 'secretField', optional: false, type: 'string' }],
    childIdentities: [],
}

const arrayOp: OperationMeta = {
    command: 'custom:govgroup-emails',
    modulePath: '/fake/govgroup-emails.ts',
    input: [{ name: 'groupName', optional: true, type: 'string' }],
    output: [{ name: 'emails', optional: false, type: 'string[]' }],
    childIdentities: [],
}

describe('buildAccountSchema', () => {
    it('includes core attrs with identityAttribute id and name account', () => {
        const schema = buildAccountSchema([exampleOp])
        expect(schema.name).toBe('account')
        expect(schema.identityAttribute).toBe('id')
        expect(schema.displayAttribute).toBe('id')
        expect(schema.nativeObjectType).toBe('User')
        const names = schema.attributes.map((a) => a.name)
        expect(names).toContain('id')
        expect(names).toContain('status')
        expect(names).toContain('date')
    })

    it('merges output fields from registered operations', () => {
        const schema = buildAccountSchema([exampleOp])
        const names = schema.attributes.map((a) => a.name)
        expect(names).toContain('summary')
        expect(names).toContain('step')
    })

    it('excludes reserved key sourceId', () => {
        const schema = buildAccountSchema([exampleOp])
        const names = schema.attributes.map((a) => a.name)
        expect(names).not.toContain('sourceId')
    })

    it('maps string[] output fields to isMulti true', () => {
        const schema = buildAccountSchema([arrayOp])
        const emails = schema.attributes.find((attr) => attr.name === 'emails')

        expect(emails).toEqual(
            expect.objectContaining({
                type: 'STRING',
                isMulti: true,
            })
        )
    })

    it('maps scalar output fields to isMulti false', () => {
        const schema = buildAccountSchema([exampleOp])
        const summary = schema.attributes.find((attr) => attr.name === 'summary')

        expect(summary).toEqual(
            expect.objectContaining({
                type: 'STRING',
                isMulti: false,
            })
        )
    })

    it('uses typed inference for non-string output fields', () => {
        const typedOp: OperationMeta = {
            command: 'custom:typed',
            modulePath: '/fake/typed.ts',
            input: [],
            output: [
                { name: 'count', optional: false, type: 'number' },
                { name: 'active', optional: false, type: 'boolean' },
            ],
            childIdentities: [],
        }
        const schema = buildAccountSchema([typedOp])

        expect(schema.attributes.find((attr) => attr.name === 'count')).toEqual(
            expect.objectContaining({ type: 'INT', isMulti: false })
        )
        expect(schema.attributes.find((attr) => attr.name === 'active')).toEqual(
            expect.objectContaining({ type: 'BOOLEAN', isMulti: false })
        )
    })

    it('excludes unregistered operations when not passed in', () => {
        const schema = buildAccountSchema([exampleOp])
        const names = schema.attributes.map((a) => a.name)
        expect(names).not.toContain('secretField')
    })

    it('merges fields from multiple operations', () => {
        const schema = buildAccountSchema([exampleOp, unregisteredOp])
        const names = schema.attributes.map((a) => a.name)
        expect(names).toContain('secretField')
    })
})
