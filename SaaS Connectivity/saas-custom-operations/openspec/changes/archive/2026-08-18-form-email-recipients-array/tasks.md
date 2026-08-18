## 1. Sod remediation output contract

- [x] 1.1 Change `SodRemediationOperation.output` key to `'sod-remediation:form-email-recipients': string[]` in `src/operations/sod-remediation/index.ts`
- [x] 1.2 Persist `[ownerEmail]` instead of scalar `ownerEmail` in `ctx.persist` and update `logSodRemediationOutput` / logging keys in `logging.ts`
- [x] 1.3 Run `npm run codegen:schemas` and confirm `index.schema.ts` emits `'sod-remediation:form-email-recipients': 'string[]'`
- [x] 1.4 Update persist and schema assertions in `src/operations/sod-remediation/index.spec.ts` (`isMulti: true`, array values)
- [x] 1.5 Update `src/operations/sod-remediation/logging.spec.ts` if output log keys change

## 2. Access sod remediation output contract

- [x] 2.1 Change `AccessSodRemediationOperation` child output key to `'access-sod-remediation:form-email-recipients': string[]` in `index.ts`
- [x] 2.2 Persist `[ownerEmail]` on child identities in `ctx.persist`
- [x] 2.3 Run codegen and confirm `index.schema.ts` sidecar uses `'string[]'`
- [x] 2.4 Update schema attribute expectations in `src/operations/access-sod-remediation/index.spec.ts`

## 3. Codegen and workflow

- [x] 3.1 Update sod-remediation quoted-identifier fixture in `scripts/generate-operation-schemas.spec.ts` if present
- [x] 3.2 Update Send Email JSONPath in `workflows/SOD Remediation - Violation Response.json` to `form-email-recipients`

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 All delta spec scenarios covered by sod-remediation and access-sod-remediation persist tests

## 5. Documentation

- [x] 5.1 Update output tables and workflow steps in `src/operations/sod-remediation/README.md`
- [x] 5.2 Update output tables and workflow steps in `src/operations/access-sod-remediation/README.md`
- [x] 5.3 Update bundled workflow JSON (covered in 3.2) and note breaking JSONPath migration for consumers

## 6. Changelog

- [x] 6.1 Create or update changelog entry via **changelog-generator** during apply
- [x] 6.2 Confirm entry documents breaking rename `form-email-recipient` → `form-email-recipients` and scalar → `string[]` type change
