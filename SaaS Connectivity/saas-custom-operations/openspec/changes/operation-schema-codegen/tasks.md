## 1. Codegen script

- [x] 1.1 Add `scripts/generate-operation-schemas.ts` with `generateOperationSchemas()` using `parseRegistrations` and `extractOperationSignature`
- [x] 1.2 Emit `{basename}.schema.ts` exporting `{handlerName}Schema` via `defineOperationSchema`
- [x] 1.3 Add auto-generated file banner and stable alphabetical field ordering
- [x] 1.4 Exit non-zero with clear error when OperationSignature is missing on a registered handler

## 2. Codegen tests

- [x] 2.1 Add `scripts/generate-operation-schemas.spec.ts` covering sidecar content for example operation
- [x] 2.2 Test failure path when handler module lacks OperationSignature
- [x] 2.3 Test field parity with `extractOperationSignature` / templates introspection

## 3. npm scripts and prebuild

- [x] 3.1 Add `codegen:schemas` script to `package.json`
- [x] 3.2 Wire `prebuild` to run `codegen:schemas` before `ncc build`
- [x] 3.3 Run initial codegen and commit generated `example-operation.schema.ts`

## 4. Operation module migration

- [x] 4.1 Update `example-operation.ts` to import `exampleOperationSchema` from sidecar
- [x] 4.2 Update `_template.ts` to document sidecar import pattern
- [x] 4.3 Remove inline manual `defineOperationSchema` blocks from operation modules

## 5. Documentation

- [x] 5.1 Update README — single source of truth in OperationSignature; sidecar generated at build
- [x] 5.2 Note parser limitations (inline output literals only) in README or AGENTS.md

## 6. Verification

- [x] 6.1 Run `npm test` — full suite passes
- [x] 6.2 Run `npm run build` — prebuild regens sidecars and bundle succeeds
- [x] 6.3 Update CHANGELOG with codegen feature and authoring migration note
