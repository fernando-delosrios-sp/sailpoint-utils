## Why

Adding a custom operation still requires editing four places: the operation module, `index.ts` registration, `connector-spec.json` commands, and the generated schema sidecar import. The `command` name is declared separately in each location and drifts easily.

`OperationSignature` is already the author's mental model for an operation contract. An optional `command` field on that interface — combined with existing build-time introspection — can drive registration, manifest sync, and schema wiring for the common case while preserving manual registration for legacy or exceptional handlers.

## What Changes

- Add optional **`command?: string`** to `OperationSignature`; auto-discovered ops declare `command: 'custom:…'` as a string literal on the extending interface
- Extend **`npm run codegen:schemas`** (prebuild) to:
  - Scan `src/operations/*.ts` for modules with `command` literal + single `customOperation` export
  - Emit **`src/operations/auto-registry.ts`** registering auto-discovered handlers
  - Register auto-op schemas via runtime **`registerOperationSchema`**
  - **Sync `connector-spec.json` `commands[]`** from all discovered ops (auto + manual)
- Add framework **schema registry** with lookup by `context.commandType` when `operationSchema` is omitted (auto ops only)
- **Fail build** on duplicate commands (auto vs manual), multiple exports per file, missing export, or non-`custom:` command prefix
- Migrate **`example-operation`** to auto-discovery pattern (no `index.ts` line, no `operationSchema` import)
- Update **`loadOperationMeta`** / templates generator to use unified discovery

## Capabilities

### Modified Capabilities

- `connector-operations`: auto-discovery registration via generated `auto-registry.ts`; hybrid manual registration for ops without `command`
- `custom-operation-framework`: optional `command` on `OperationSignature`; schema registry fallback for auto-discovered ops
- `connector-config`: codegen-owned `commands[]` sync in `connector-spec.json`
- `templates-generator`: unified operation discovery (auto + manual) instead of index-only parsing

## Impact

- Modify: `src/framework/output-schema.ts`, `with-custom-operation.ts`, new `operation-schema-registry.ts`
- Modify: `scripts/templates/operation-introspection.ts`, `scripts/generate-operation-schemas.ts`
- New generated: `src/operations/auto-registry.ts` (committed)
- Modify: `src/operations/index.ts`, `example-operation.ts`, `_template.ts`
- Modify: `connector-spec.json` (commands maintained by codegen)
- Tests: introspection, codegen, schema registry, collision failures
- Docs: README, CHANGELOG

## Non-Goals

- Runtime AST parsing on invoke
- Auto-wiring `operationSchema` for manually registered ops
- Multiple operations per file
- Non-literal `command` values (aliases, const refs)
- Manifest-only commands (declared in spec but not implemented)
