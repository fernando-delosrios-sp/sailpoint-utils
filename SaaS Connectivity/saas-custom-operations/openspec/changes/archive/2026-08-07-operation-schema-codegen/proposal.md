## Why

Custom operations declare output types twice: once in an `OperationSignature` interface (compile-time) and again in `defineOperationSchema(...)` (runtime). This duplication drifts easily and frustrates authors who expect the interface to be sufficient.

The templates generator already extracts output fields from operation source files — that knowledge should feed runtime schema reconciliation without manual copy-paste.

## What Changes

- Add **`npm run codegen:schemas`** (also runs in **`prebuild`**) that generates **per-operation sidecar files** (e.g. `example-operation.schema.ts`)
- Sidecars export `*OperationSchema` via `defineOperationSchema(...)`, derived from the operation's `OperationSignature.output` literal
- **Auto-discovery:** ops with `command` literal get `auto-registry.ts` wiring (schema registry + connector registration) and `connector-spec.json` sync
- **Manual registration:** import generated sidecar and pass `{ operationSchema }` to `customOperation`
- **Shared introspection** — codegen reuses `operation-introspection.ts` (same rules as `npm run templates`)
- **Build failure** when a discovered operation lacks a parseable `OperationSignature`
- Update `_template.ts`, README, and AGENTS.md for the new pattern

## Capabilities

### Modified Capabilities

- `templates-generator`: shared introspection module; codegen consumes same parser
- `custom-operation-framework`: codegen sidecars as supported way to supply `operationSchema`; auto-registry for discovered ops

### New Capabilities

- `operation-schema-codegen`: build-time sidecar generation, auto-registry, prebuild hook, committed sidecar convention

## Impact

- New: `scripts/generate-operation-schemas.ts`, `scripts/generate-operation-schemas.spec.ts`
- New: `src/operations/*.schema.ts`, `src/operations/auto-registry.ts` (generated, committed)
- Modify: `package.json` scripts (`codegen:schemas`, `prebuild`)
- Modify: `src/operations/example-operation.ts`, `_template.ts` — auto-discovery pattern
- Modify: `connector-spec.json` — `commands[]` synced by codegen
- Tests: codegen unit tests; registry resolution tests
- Docs: README operation authoring section, AGENTS.md parser limitations

## Non-Goals

- Central registry file authored by hand (Option A)
- Runtime AST parsing on invoke
- Removing `defineOperationSchema` helper (codegen still emits it)
- Parsing imported/type-alias output shapes in v1
