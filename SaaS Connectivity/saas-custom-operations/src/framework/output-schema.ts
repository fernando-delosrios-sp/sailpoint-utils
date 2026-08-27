/** Framework-managed account attribute names — not part of operation output types. */
export const RESERVED_OUTPUT_KEYS = new Set(['id', 'sourceId', 'date', 'status', 'operationName'])

/**
 * Combined input/output/response contract for a custom operation (plain TypeScript shapes).
 * Optional `command` string literal enables build-time auto-registration and manifest sync.
 *
 * - `output` — persisted attributes only (`ctx.persist`); sole feed for the result-source account schema
 * - `response` — optional author summary typed into the operation response envelope `summary` (`ctx.respond`)
 */
export interface OperationSignature {
    /** When set as a string literal, codegen auto-registers this operation (no manual index.ts entry). */
    command?: string
    input: object
    /** Attributes written via `ctx.persist` — never `ctx.res.send` / response summary content. */
    output: object
    /** Optional per-operation summary detail for the operation response envelope (`ctx.respond`). */
    response?: object
}

/**
 * Typed `ctx.res.send` payload built by {@link RequestContext.respond}.
 * Distinct from persisted `output`; never contributes account schema attributes.
 */
export interface OperationResponse<TSummary extends object = Record<string, unknown>> {
    /** Operation/command name (e.g. `custom:access-model-sod-remediation`). */
    name: string
    /** Outcome status; defaults to `success` when omitted from `ctx.respond`. */
    status: string
    /** Native identities persisted during this invoke (response id list). */
    responses: string[]
    /** Per-operation response detail typed from `OperationSignature['response']`. */
    summary: TSummary
}

export type InferOperationInput<T extends OperationSignature> = T['input']
export type InferOperationOutput<T extends OperationSignature> = T['output']
export type InferOperationResponse<T extends OperationSignature> = T extends {
    response: infer R extends object
}
    ? R
    : Record<string, unknown>

