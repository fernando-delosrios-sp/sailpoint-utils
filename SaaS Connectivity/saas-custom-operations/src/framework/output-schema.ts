/** Framework-managed account attribute names — not part of operation output types. */
export const RESERVED_OUTPUT_KEYS = new Set(['id', 'sourceId', 'date', 'status', 'operationName'])

/**
 * Combined input/output contract for a custom operation (plain TypeScript shapes).
 * Optional `command` string literal enables build-time auto-registration and manifest sync.
 */
export interface OperationSignature {
    /** When set as a string literal, codegen auto-registers this operation (no manual index.ts entry). */
    command?: string
    input: object
    output: object
}

export type InferOperationInput<T extends OperationSignature> = T['input']
export type InferOperationOutput<T extends OperationSignature> = T['output']

