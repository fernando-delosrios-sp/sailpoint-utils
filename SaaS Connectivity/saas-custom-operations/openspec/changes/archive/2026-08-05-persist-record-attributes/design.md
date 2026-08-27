## Context

The custom-operation framework writes operation output to a dummy ISC source via `ctx.persist()`. The helper accepted a positional `string[]` mapped to `param1`..`param9` with no typed contract.

## Goals / Non-Goals

**Goals:**
- Replace positional params with named record attributes on `ctx.persist`
- Single `OperationSignature` interface per operation with plain TypeScript `input` and `output` fields
- `customOperation<T>(handler)` — handler only; types flow from `T`
- Auto-serialize values for ISC string attributes; preserve verify-default / verify-false / `verifyPersisted`
- Update specs, tests, example operation, template, README, CHANGELOG

**Non-Goals:**
- ISC schema literals (`'string' | 'json'`) on output types
- Runtime persist key validation or `sourceSchemaHints()` — compile-time typing only
- Auto-provisioning ISC sources
- Backward-compatible array persist overload

## Decisions

### D1: OperationSignature (input + output)

- **Choice:** `interface MyOperation extends OperationSignature { input: {...}; output: {...} }` with normal TS types (`string`, `string[]`, optional fields)
- **Reason:** One contract for invoke input and persist output; no ISC coupling in types

### D2: customOperation handler-only registration

- **Choice:** `customOperation<MyOperation>(async (ctx, input) => { ... })` — no separate output config object
- **Reason:** Interface is the single type source; duplicate runtime schema defeated the purpose

### D3: Compile-time persist typing

- **Choice:** `PersistFn<TOutput>` accepts `Partial<TOutput>`; no runtime undeclared-key rejection
- **Reason:** TypeScript is the guardrail; avoids duplicate schema maintenance

### D4: Value serialization

- **Choice:** Auto-detect — string as-is, primitives via `String()`, arrays/objects via `JSON.stringify`, omit null/undefined
- **Reason:** Authors use native JS shapes in output interface; framework handles ISC storage

### D5: Reserved framework keys

- **Choice:** Framework sets `id`, `sourceId`, `date`, `status`; author keys with those names ignored at persist time
- **Reason:** Preserves identity and timestamp semantics

## Risks / Trade-offs

- [Trade-off] No runtime persist validation → Mitigation: strict TS output types on OperationSignature
- [Trade-off] Breaking API from param slots → Accepted: early scaffold

## Migration Plan

1. Refactor `persist-result.ts` for record attributes and auto serialization
2. Add `OperationSignature` and `customOperation` in framework
3. Migrate example and template operations
4. Update docs and tests
5. Run `npm test` and `npm run build`

## Open Questions

- None blocking
