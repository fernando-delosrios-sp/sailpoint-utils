## 1. Forms list-and-pick helper

- [x] 1.1 Add failing tests in `src/isc/forms/` for list-by-`formDefinitionId`, pick by instance id, second-page match, missing instance `ConnectorError`, shared `formInput`/`formData` normalization (including `formInstanceInputs`)
- [x] 1.2 Implement paginated `searchFormInstancesByTenantV1` helper (limit 250, early exit, OData-escaped `formDefinitionId eq`); export from `src/isc/forms/index.ts`; leave `getFormInstanceById` in place

## 2. Apply operation contract

- [x] 2.1 Add failing apply tests: required `formDefinitionId`; list filter + pick; no `getFormInstanceByKeyV1`; later-page pick; missing instance (no PATCH); prior persist skips list (`skipped-already-applied`); missing `formDefinitionId` validation; offline still uses fixtures by `formInstanceId`
- [x] 2.2 Extend `OperationSignature.input` with required `formDefinitionId`; wire handler to list-and-pick after prior-apply check; keep persist identity `{formInstanceId}`
- [x] 2.3 Update apply mocks (`searchFormInstancesByTenantV1`), `payloads/access-model-sod-remediation-apply-offline.json`, and any invoke examples that omit `formDefinitionId`

## 3. Workflow binding

- [x] 3.1 Update `workflows/Access Model SOD - Remediation.json` invoke input with `formDefinitionId: "{{$.trigger.formDefinitionId}}"`

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 Run `npm run typecheck` and `npm test`
- [x] 4.3 All delta spec scenarios covered by named automated tests (list filter, pagination pick, missing instance, skip list on persist, offline, scan README/spec downstream invoke fields)
- [x] 4.4 `npm run build` (ncc/spcx pack) after forms client + apply handler changes

## 5. Documentation

- [x] 5.1 Update `src/operations/access-model-sod-remediation-apply/README.md` input table, invoke example, workflow table, token scopes (`searchFormInstancesByTenantV1`)
- [x] 5.2 Update `src/operations/access-model-sod-remediation/README.md` apply invoke to include `formDefinitionId`

## 6. Changelog

- [x] 6.1 Create or update changelog entry via **changelog-generator** during apply
- [x] 6.2 Confirm entry covers breaking apply input (`formDefinitionId`) and list-and-pick load (not get-by-id)
