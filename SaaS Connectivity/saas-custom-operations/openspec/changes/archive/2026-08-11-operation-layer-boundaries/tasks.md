## 1. Generic isc/forms module

- [x] 1.1 Create `src/isc/forms/error-formatting.ts` with `formatFormsApiError` extracted from sod-form-service
- [x] 1.2 Create `src/isc/forms/seed-loader.ts` — generic `loadFormSeed` and `buildCreateFormDefinitionPayload` (no hardcoded SOD seed)
- [x] 1.3 Create `src/isc/forms/ensure-definition.ts` — `ensureFormDefinitionByName(forms, { name, ownerId, template })`
- [x] 1.4 Create `src/isc/forms/create-instance.ts` — `createStandaloneFormInstance` returning standAloneFormUrl
- [x] 1.5 Add unit tests for isc/forms (seed load, ensure create/reuse, instance create, ConnectorError surfacing)

## 2. Codegen subdirectory discovery

- [x] 2.1 Update `scanOperationModules` to scan `operations/<slug>/index.ts`; exclude `_template/` and root registry files
- [x] 2.2 Update `renderAutoRegistry` to emit relative imports `./<slug>/index` and `./<slug>/index.schema`
- [x] 2.3 Fix sidecar `defineOperationSchema` import depth for nested operation entries
- [x] 2.4 Add introspection tests — subdirectory discovery, `_template` excluded, duplicate command detection
- [x] 2.5 Add codegen schema tests — nested import paths in auto-registry output

## 3. Migrate example operation to subdirectory

- [x] 3.1 Move `example-operation.ts` → `operations/example/index.ts`; relocate spec and tests
- [x] 3.2 Replace flat `_template.ts` with `operations/_template/index.ts` copy scaffold
- [x] 3.3 Run codegen; verify `custom:example` still registered and sidecar at `example/index.schema.ts`

## 4. Restructure sod-remediation operation

- [x] 4.1 Create `operations/sod-remediation/index.ts` from sod-remediation-operation.ts orchestrator
- [x] 4.2 Move `sod-remediation-context.ts`, `sod-remediation-logging.ts` into sod-remediation subdirectory
- [x] 4.3 Move `access-path-resolver.ts` into `operations/sod-remediation/access-path-resolver.ts`
- [x] 4.4 Add `operations/sod-remediation/form-service.ts` — operation glue over generic isc/forms + local seed
- [x] 4.5 Move seed JSON to `operations/sod-remediation/seed/`; remove `assets/forms/sod-violation-remediation.seed.json` if superseded
- [x] 4.6 Delete polluted isc modules: `form-seed-loader.ts`, `sod-form-service.ts`, `sod-remediation-context.ts`, `sod-remediation-logging.ts`
- [x] 4.7 Relocate and update sod-remediation unit tests for new paths; verify all connector-operations/sod-remediation scenarios

## 5. Integration updates

- [x] 5.1 Update `scripts/call-op.ts` imports to subdirectory paths
- [x] 5.2 Update `vitest.config.ts` exclusions for `_template` subdirectory
- [x] 5.3 Run `npm run codegen:schemas` and confirm connector-spec.json commands unchanged
- [x] 5.4 Run full `npm test` and `npm run build`

## 6. Documentation

- [x] 6.1 Update README — mandatory `operations/<slug>/index.ts` layout, isc/forms vs operation domain boundary, promotion rules
- [x] 6.2 Update `_template` scaffold comments for subdirectory authoring workflow
- [x] 6.3 Update inline JSDoc on isc/forms public APIs

## 7. Changelog

- [x] 7.1 Create or update changelog entry via changelog-generator skill
- [x] 7.2 Confirm entry covers structural refactor and unchanged operation I/O contracts
