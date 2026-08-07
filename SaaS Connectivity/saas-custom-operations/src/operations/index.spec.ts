import { describe, expect, it, vi } from 'vitest'
import { customOperation, OperationSignature } from '../framework'
import { registerAutoOperations } from './auto-registry'

interface ManualOperation extends OperationSignature {
    input: { payload?: string }
    output: { result: string }
}

describe('registerCommands manual chaining', () => {
    it('registers auto-discovered and manually chained commands on the connector', () => {
        const handlers = new Map<string, unknown>()
        const connector = {
            command: vi.fn((command: string, handler: unknown) => {
                handlers.set(command, handler)
                return connector
            }),
        }

        const manualOperation = customOperation<ManualOperation>(async () => {})
        registerAutoOperations(connector as any).command('custom:manual', manualOperation)

        expect(handlers.has('custom:example')).toBe(true)
        expect(handlers.has('custom:manual')).toBe(true)
        expect(connector.command).toHaveBeenCalledWith('custom:example', expect.any(Function))
        expect(connector.command).toHaveBeenCalledWith('custom:manual', manualOperation)
    })
})
