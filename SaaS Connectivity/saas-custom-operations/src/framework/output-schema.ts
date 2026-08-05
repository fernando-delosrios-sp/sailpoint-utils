/** Framework-managed account attribute names — not part of operation output types. */
export const RESERVED_OUTPUT_KEYS = new Set(['id', 'sourceId', 'date', 'status'])

/** Combined input/output contract for a custom operation (plain TypeScript shapes). */
export interface OperationSignature {
    input: object
    output: object
}

export type InferOperationInput<T extends OperationSignature> = T['input']
export type InferOperationOutput<T extends OperationSignature> = T['output']
