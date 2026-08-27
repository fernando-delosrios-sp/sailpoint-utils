import { OperationField } from './schema-inference'
import { OperationSchemaContract } from './types'

/** TypeScript type text or field metadata for schema reconciliation. */
export type OperationFieldSpec = string | { type: string; optional?: boolean }

function toOperationField(name: string, spec: OperationFieldSpec): OperationField {
    if (typeof spec === 'string') {
        return { name, type: spec, optional: false }
    }
    return { name, type: spec.type, optional: spec.optional ?? false }
}

/**
 * Builds an {@link OperationSchemaContract} from output field type specs.
 * Pass the result to {@link customOperation} so persist can reconcile the result source schema.
 */
export function defineOperationSchema(
    fields: Record<string, OperationFieldSpec>,
    options?: { command?: string }
): OperationSchemaContract {
    const outputFields = Object.entries(fields)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([name, spec]) => toOperationField(name, spec))

    return {
        command: options?.command,
        outputFields,
    }
}
