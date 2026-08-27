## 1. Operation input + handler gating

- [x] 1.1 Add optional `disableLinks?: boolean` to `AccessModelSodRemediationOperation` input in `src/operations/access-model-sod-remediation/index.ts`; gate `uiOrigin` with `input.disableLinks === true` before group HTML / situation summary assembly
- [x] 1.2 Add optional `disableLinks?: boolean` to `SodRemediationOperation` input in `src/operations/sod-remediation/index.ts`; gate `uiOrigin` the same way before `assembleFormInput`
- [x] 1.3 Run schema codegen / prebuild so both commands stay registered in `auto-registry.ts` and `connector-spec.json` `commands[]`; `disableLinks` lives on `OperationSignature.input` (codegen syncs commands + output sidecars, not per-command input schemas)

## 2. Tests

- [x] 2.1 In `access-model-sod-remediation` specs: cover omit/`false` keep ISC UI links online; `true` omits admin anchors in situation summary and group columns; form URL + email CTA still present
- [x] 2.2 In `sod-remediation` specs: same omit/`false`/`true` coverage for situation summary and group column HTML; form URL + email CTA still present

## 3. Verification

- [x] 3.1 Confirm canonical test command: `npm test`
- [x] 3.2 Run `npm run typecheck` and `npm test`
- [x] 3.3 All delta spec scenarios covered by named automated tests
- [x] 3.4 Confirm both custom commands remain in `connector-spec.json` `commands[]` after codegen, and both signatures declare optional `disableLinks`

## 4. Documentation

- [x] 4.1 Update `src/operations/access-model-sod-remediation/README.md` input table/notes for `disableLinks`
- [x] 4.2 Update `src/operations/sod-remediation/README.md` input table/notes for `disableLinks` (clarify form URL / email CTA unchanged)
- [x] 4.3 Update package `README.md` or command input docs if they enumerate operation inputs

## 5. Changelog

- [x] 5.1 Create or update changelog entry via **changelog-generator** during apply
- [x] 5.2 Confirm entry covers optional `disableLinks` for both remediation launch commands
