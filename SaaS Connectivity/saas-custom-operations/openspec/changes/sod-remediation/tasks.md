## 1. Seed form asset and ISC clients

- [x] 1.1 Add bundled seed form JSON at `assets/forms/sod-violation-remediation.seed.json` with formInput declarations, DESCRIPTION context blocks, single `remediationSide` SELECT, hidden workflow keys, and tenant-control SELECT data source placeholder
- [x] 1.2 Extend `sdk-factory.ts` and `types.ts` to expose `CustomFormsApi` on `ctx.sdk`
- [x] 1.3 Add `src/isc/experimental-client.ts` (or equivalent) for `GET /violations/v1/:id` and `GET /controls/v1` with experimental header
- [x] 1.4 Add `src/isc/access-path-resolver.ts` to expand entitlement conflicts to AP/role paths and build revoke payloads

## 2. Sod remediation operation

- [x] 2.1 Create `src/operations/sod-remediation-operation.ts` with `command: 'custom:sod-remediation'` and typed input/output (`violationId`, `formName`, `owner?` → `formUrl`, `situationSummary`)
- [x] 2.2 Implement form definition ensure-by-name (search → create from seed)
- [x] 2.3 Implement form instance create with recipient resolution, formInput assembly, and situation summary generation
- [x] 2.4 Run codegen prebuild to register operation and sync connector-spec.json

## 3. Tests and fixtures

- [x] 3.1 Unit test experimental violations/controls client with mocked HTTP
- [x] 3.2 Unit test access-path resolver (entitlement-only, AP-granted, role-granted, warnings)
- [x] 3.3 Unit test sod-remediation handler (form create path, recipient override, missing form definition seed create, zero controls)
- [x] 3.4 Add operation payload under `payloads/` and register handler in `scripts/call-op.ts`
- [x] 3.5 Run `npm test` and confirm coverage thresholds

## 4. Documentation

- [x] 4.1 Document `custom:sod-remediation` invoke contract and workflow integration pattern in README
- [x] 4.2 Update CHANGELOG via changelog-generator skill
