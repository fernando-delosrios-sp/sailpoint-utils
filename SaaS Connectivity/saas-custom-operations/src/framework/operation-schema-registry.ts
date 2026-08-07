import { OperationSchemaContract } from './types'

const registry = new Map<string, OperationSchemaContract>()

/** Registers an operation schema sidecar for runtime lookup by command name. */
export function registerOperationSchema(command: string, schema: OperationSchemaContract): void {
    registry.set(command, schema)
}

/** Returns a registered schema for auto-discovered operations, if present. */
export function getOperationSchema(command: string): OperationSchemaContract | undefined {
    return registry.get(command)
}

/** Clears the registry — for unit tests only. */
export function clearOperationSchemaRegistry(): void {
    registry.clear()
}
