## Why

Custom operations declare output types twice: once in an `OperationSignature` interface (compile-time) and again in `defineOperationSchema(...)` (runtime). This duplication drifts easily and frustrates authors who expect the interface to be sufficient.

The templates generator already extracts output fields from operation source files — that knowledge should feed runtime schema reconciliation without manual copy-paste.

## What Changes

- Add **`npm run codegen:schemas`** (also runs in **`prebuild`**) that generates **per-operation sidecar files** (e.g. `example-operation.schema.ts`)
- Sidecars export `*OperationSchema` via `defineOperationSchema(...)`, derived from the operation's `OperationSignature.output` literal
- Operation modules **import the sidecar** instead of hand-authoring `defineOperationSchema`
- **Shared introspection** — codegen reuses `operation-introspection.ts` (same rules as `npm run templates`)
- **Build failure** when a registered operation lacks a parseable `OperationSignature` or sidecar is stale/missing after codegen
- Update `_template.ts`, README, and `_template` docs for the new pattern

## Capabilities

### Modified Capabilities

- `templates-generator`: shared introspection module; optional note that codegen consumes same parser
- `custom-operation-framework`: document codegen as the supported way to supply `operationSchema`; deprecate manual field maps in operation files

### New Capabilities

- `operation-schema-codegen`: build-time sidecar generation, prebuild hook, committed sidecar convention

## Impact

- New: `scripts/generate-operation-schemas.ts`, `scripts/generate-operation-schemas.spec.ts`
- New: `src/operations/*.schema.ts` (generated, committed)
- Modify: `package.json` scripts (`codegen:schemas`, `prebuild`)
- Modify: `src/operations/example-operation.ts`, `_template.ts` — import sidecar
- Modify: `scripts/templates/operation-introspection.ts` — extract shared bits if needed
- Tests: codegen unit tests; update operation registration tests
- Docs: README operation authoring section

## Non-Goals

- Central registry file (Option A)
- Runtime AST parsing on invoke
- Removing `defineOperationSchema` helper (codegen still emits it)
- Parsing imported/type-alias output shapes in v1
