## 1. ISC target-client helpers

- [x] 1.1 Add `getFormInstanceById` (or equivalent) under `src/isc/forms/` with normalization and tests
- [x] 1.2 Add role patch helpers (`detachRoleAccessProfiles`, `removeRoleEntitlements`, `appendRoleDescription`) under `src/isc/roles/` with tests
- [x] 1.3 Add access profile patch helpers (`removeAccessProfileEntitlements`, `appendAccessProfileDescription`) under `src/isc/access-profiles/` with tests

## 2. Operation implementation

- [x] 2.1 Scaffold `src/operations/access-model-sod-remediation-apply/` with `command: 'custom:access-model-sod-remediation-apply'` OperationSignature, README, and offline payload
- [x] 2.2 Implement form instance parse + validation (`parse-form-instance.ts`) with tests
- [x] 2.3 Implement correction plan builder reusing entitlement expansion (`build-correction-plan.ts`) with tests for role AP detach vs direct ent and AP access-item path
- [x] 2.4 Implement catalog apply + description audit (`apply-correction.ts`, `description-audit.ts`) with tests
- [x] 2.5 Wire handler: fetch form → plan → apply → persist on `{formInstanceId}` → `ctx.res.send`; idempotent skip path
- [x] 2.6 Add offline fixtures and `call:op` payload; register in `scripts/call-op.ts`

## 3. Connector registration

- [x] 3.1 Run codegen / verify `connector-spec.json` and `auto-registry.ts` include `custom:access-model-sod-remediation-apply`
- [x] 3.2 Add operation integration spec in `index.spec.ts`

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 All delta spec scenarios covered by named automated tests

## 5. Documentation

- [x] 5.1 Add `src/operations/access-model-sod-remediation-apply/README.md` with workflow invoke example (`formInstanceId` only) and token scopes
- [x] 5.2 Update `src/operations/access-model-sod-remediation/README.md` workflow step 5 to reference `custom:access-model-sod-remediation-apply`
- [x] 5.3 Update root README custom operations table

## 6. Changelog

- [x] 6.1 Create or update changelog entry for this change via changelog-generator
- [x] 6.2 Confirm entry covers new command and role AP detach semantics
