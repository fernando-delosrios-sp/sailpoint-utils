import { describe, expect, it, vi } from 'vitest'
import { customOperation, OperationSignature } from '../framework'
import { exampleOperation } from './example-operation'
import { registerCommands } from './index'

interface ManualOperation extends OperationSignature {
    input: { payload?: string }
    output: { result: string }
}

describe('registerCommands', () => {
    it('wraps auto-discovered handlers with request logging', () => {
        const handlers = new Map<string, unknown>()
        const connector = {
            command: vi.fn((command: string, handler: unknown) => {
                handlers.set(command, handler)
                return connector
            }),
        }

        registerCommands(connector as never)

        expect(handlers.get('custom:example')).toBeDefined()
        expect(handlers.get('custom:example')).not.toBe(exampleOperation)
        expect(handlers.get('custom:sod-remediation')).toBeDefined()
    })
})

describe('registerCommands manual chaining', () => {
    it('registers auto-discovered and manually chained commands on the connector', () => {
        const handlers = new Map<string, unknown>()
        const commandSpy = vi.fn(function (this: { command: typeof commandSpy }, command: string, handler: unknown) {
            handlers.set(command, handler)
            return this
        })
        const connector = { command: commandSpy }

        const manualOperation = customOperation<ManualOperation>(async () => {})
        registerCommands(connector as never).command('custom:manual', manualOperation)

        expect(handlers.has('custom:example')).toBe(true)
        expect(handlers.has('custom:sod-remediation')).toBe(true)
        expect(handlers.has('custom:manual')).toBe(true)
        expect(commandSpy).toHaveBeenCalledWith('custom:example', expect.any(Function))
        expect(commandSpy).toHaveBeenCalledWith('custom:sod-remediation', expect.any(Function))
        expect(commandSpy).toHaveBeenCalledWith('custom:manual', expect.any(Function))
        expect(handlers.get('custom:manual')).not.toBe(manualOperation)
    })
})


