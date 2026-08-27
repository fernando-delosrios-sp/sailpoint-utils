## Why

Custom operations persist workflow results via `ctx.persist()`, but the second argument is a positional `string[]` mapped to opaque `param1`..`param9` slots. Authors need self-documenting persist calls with a single TypeScript contract for invoke input and persist output, without duplicating runtime schema configuration.

## What Changes

**Persist API second argument**
- From: `persist(id, params?: string[], status?, options?)` — positional mapping to param1..param9
- To: `persist(id, attributes?: Partial<TOutput>, status?, options?)` — named keys from `OperationSignature.output`
- Impact: **Breaking** — all persist call sites migrate to record attributes

**Operation registration**
- From: `withCustomOperation(handler)` with untyped or separate input generic
- To: `OperationSignature` interface + `customOperation<T>(handler)` — one interface types input and persist output
- Impact: **Breaking** — operations declare `extends OperationSignature`

**Serialization**
- Framework auto-serializes values for ISC string attributes (JSON for arrays/objects)
- Output interface stays plain TypeScript — not ISC schema literals

## Capabilities

### Modified Capabilities

- `custom-operation-framework`: OperationSignature, customOperation, typed record persist, auto serialization
- `connector-config`: README documents OperationSignature pattern for dummy source attributes

## Impact

- `src/framework/output-schema.ts`, `persist-result.ts`, `with-custom-operation.ts`, `types.ts`
- `src/operations/example-operation.ts`, `_template.ts`
- `README.md`, `CHANGELOG.md`
- `vitest.config.ts` — exclude unwired endpoint-migration service stubs from coverage denominator
