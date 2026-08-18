## 1. Persist output contract

- [x] 1.1 Update `SodRemediationOperation.output` keys in `src/operations/sod-remediation/index.ts` and persist/`logSodRemediationOutput` attribute names
- [x] 1.2 Update persist assertions and schema attribute list in `src/operations/sod-remediation/index.spec.ts` (launch, recipient, header, body, minimal contract)
- [x] 1.3 Run `npm run codegen:schemas` so `index.schema.ts` regenerates with the new keys

## 2. Codegen fixture

- [x] 2.1 Update quoted-identifier fixture in `scripts/generate-operation-schemas.spec.ts` to use the new `form-email-*` keys

## 3. Documentation

- [x] 3.1 Update output table and workflow steps in `src/operations/sod-remediation/README.md`
- [x] 3.2 Update JSDoc on `buildPersistedSituationSummary` in `src/operations/sod-remediation/context.ts` to name `form-email-body`
- [x] 3.3 Update Send Email JSONPaths in `workflows/SOD Remediation - Violation Response.json`

## 4. Documentation (mandatory)

- [x] 4.1 Update README / getting-started for user-visible changes — covered by 3.1 operation README; root README has no inline sod-remediation output table
- [x] 4.2 Update API / connector docs for contract changes — operation README + bundled workflow JSON (3.1, 3.3)
- [x] 4.3 Update inline docs (JSDoc, config examples) — covered by 3.2

## 5. Changelog

- [x] 5.1 Create or update changelog entry (apply invokes **changelog-generator**)
- [x] 5.2 Confirm entry covers user-visible breaking persist key rename and workflow JSONPath migration
