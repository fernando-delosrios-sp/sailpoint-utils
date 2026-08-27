## 1. Introspection and discovery

- [x] 1.1 Add `command?: string` to `OperationSignature` in `src/framework/output-schema.ts`
- [x] 1.2 Add `scanOperationModules`, `extractCommandLiteral`, `findCustomOperationExport` to `operation-introspection.ts`
- [x] 1.3 Implement `discoverAutoOperations` and `discoverAllOperations` with collision validation
- [x] 1.4 Add unit tests for command extraction, single-export rule, duplicate detection, and `_template.ts` exclusion

## 2. Schema registry (auto ops)

- [x] 2.1 Add `operation-schema-registry.ts` with `registerOperationSchema` and `getOperationSchema`
- [x] 2.2 Wire fallback lookup in `customOperation` when `operationSchema` is omitted
- [x] 2.3 Add unit tests for registry lookup, explicit override, and manual op without registry entry

## 3. Codegen expansion

- [x] 3.1 Extend `generate-operation-schemas.ts` to use `discoverAllOperations` for sidecar generation (all ops)
- [x] 3.2 Emit generated `src/operations/auto-registry.ts` with handler registration and `registerOperationSchema` calls
- [x] 3.3 Sync `connector-spec.json` `commands[]` from discovered ops; preserve other keys
- [x] 3.4 Fail build on invalid command prefix, 0/2+ exports, and duplicate commands
- [x] 3.5 Add codegen tests for auto-registry content, manifest sync, and collision failure paths

## 4. Operations migration

- [x] 4.1 Add `command: 'custom:example'` to `example-operation.ts`; remove sidecar import and `operationSchema` option
- [x] 4.2 Update `index.ts` to call `registerAutoOperations`; remove manual example registration
- [x] 4.3 Update `_template.ts` to document auto-discovery vs manual registration paths
- [x] 4.4 Run codegen and commit generated `auto-registry.ts` and updated `connector-spec.json`

## 5. Templates alignment

- [x] 5.1 Update `loadOperationMeta` to use `discoverAllOperations`
- [x] 5.2 Update `generate-templates.ts` discovery comments
- [x] 5.3 Adjust templates tests for unified discovery (remove manifest-only scenario)

## 6. Documentation

- [x] 6.1 Update README operation authoring section for auto-discovery pattern and hybrid manual path
- [x] 6.2 Update AGENTS.md if discovery rules changed materially
- [x] 6.3 Update inline JSDoc on `OperationSignature` and `customOperation` for schema registry behavior

## 7. Changelog

- [x] 7.1 Create or update CHANGELOG entry via changelog-generator skill
- [x] 7.2 Confirm entry covers auto-registration, manifest sync, and manual migration path

## 8. Verification

- [x] 8.1 Run `npm test` — full suite passes
- [x] 8.2 Run `npm run build` — codegen, auto-registry, manifest sync, and bundle succeed
- [x] 8.3 Run `npm run pack-zip` or confirm prebuild chain includes new codegen outputs
