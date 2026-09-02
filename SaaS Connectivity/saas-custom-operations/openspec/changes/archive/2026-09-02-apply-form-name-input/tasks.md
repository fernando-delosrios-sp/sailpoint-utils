## 1. Forms lookup-by-name helper

- [x] 1.1 Add failing tests in `src/isc/forms/` for lookup-by-name: existing name returns id, missing name `ConnectorError`, OData-escaped quotes, no create/patch calls
- [x] 1.2 Implement `findFormDefinitionIdByName` (or equivalent) using `searchFormDefinitionsByTenantV1` with escaped `name eq`; export from `src/isc/forms/index.ts`; do not call `ensureFormDefinitionByName`

## 2. Apply operation contract

- [x] 2.1 Add failing apply tests: required `formName`; lookup then list-and-pick; no `ensureFormDefinitionByName`; no `getFormInstanceByKeyV1`; missing definition (no list, no PATCH); missing/blank `formName`; later-page pick; missing instance (no PATCH); prior persist skips lookup and list (`skipped-already-applied`); offline fixtures by `formInstanceId` with non-empty `formName` (no definition search, no instance list)
- [x] 2.2 Replace `OperationSignature.input.formDefinitionId` with required `formName`; after prior-apply check, lookup name then `getFormInstanceByDefinitionAndId`; keep persist identity `{formInstanceId}`
- [x] 2.3 Update apply mocks (`searchFormDefinitionsByTenantV1`), `payloads/access-model-sod-remediation-apply-offline.json`, and README/contract tests that still expect `formDefinitionId` on invoke
- [x] 2.4 Run codegen (`npm run codegen:schemas`) so auto-registry / connector-spec stay aligned with the new input field

## 3. Workflow binding

- [x] 3.1 Update `workflows/Access Model SOD - Remediation.json` invoke input: `formName` `Access Model SOD Remediation` (same as Analysis); keep `formInstanceId` from `{{$.trigger.formInstanceId}}`; leave the form-submitted trigger `formDefinitionId` filter unchanged

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 Run `npm run typecheck` and `npm test`
- [x] 4.3 All delta spec scenarios covered by named automated tests (lookup, missing definition, list filter after resolve, pagination pick, missing instance, skip lookup+list on persist, blank `formName`, offline, scan downstream invoke uses `formName`)
- [x] 4.4 `npm run build` (ncc/spcx pack) after forms helper + apply handler changes

## 5. Documentation

- [x] 5.1 Update `src/operations/access-model-sod-remediation-apply/README.md` input table, invoke example, workflow table, and list-load description (`formName` lookup then list-and-pick)
- [x] 5.2 Update `src/operations/access-model-sod-remediation/README.md` apply invoke and Remediation workflow notes to pass `formName` instead of `formDefinitionId`

## 6. Changelog

- [x] 6.1 Create or update changelog entry via **changelog-generator** during apply
- [x] 6.2 Confirm entry covers breaking apply input (`formDefinitionId` → `formName`) and lookup-then-list load
