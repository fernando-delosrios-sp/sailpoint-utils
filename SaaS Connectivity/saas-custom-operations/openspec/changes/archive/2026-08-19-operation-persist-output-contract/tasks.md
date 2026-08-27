## 1. Framework: response envelope + persisted-only output

- [x] 1.1 Add optional `response?: object` to `OperationSignature` and export `OperationResponse<TSummary>` (`name`, `status`, `responses`, `summary`) in `src/framework/output-schema.ts`; document `output` as persisted-attributes-only in `src/framework/output-schema.ts` / `types.ts` JSDoc
- [x] 1.2 Extend `RequestContext<TOutput, TSummary = Record<string, unknown>>` and add `respond(summary: TSummary, status?: string): void` that builds the envelope from the persist write registry ids and calls `ctx.res.send` (`src/framework/types.ts`, `src/framework/request-context.ts`)
- [x] 1.3 Expose persisted native ids from the persist write registry to `ctx.respond` (`src/framework/persist-result.ts`, `src/framework/request-context.ts`); ensure ids reflect all `ctx.persist` calls in the invoke
- [x] 1.4 Tests (RED→GREEN) in `src/framework/request-context.spec.ts` / `src/framework/with-custom-operation.spec.ts`: `ctx.respond` emits `name`/`status`/`responses`/`summary`; `responses` matches persisted ids; `status` defaults to `success` — covers custom-operation-framework "Operation response envelope" scenarios

## 2. Codegen: persist-output guard + persisted-only derivation

- [x] 2.1 In `scripts/templates/operation-introspection.ts`, collect object-literal keys from `ctx.persist(...)` second arguments per entry module, and parse `// persist-dynamic: <key>` markers
- [x] 2.2 In `scripts/generate-operation-schemas.ts`, fail with non-zero exit when any `output` field is absent from the persisted-key set; report module path + offending fields
- [x] 2.3 Confirm `scripts/templates/account-schema.ts` / `buildAccountSchema` derive attributes from persisted `output` only (no code change expected once operations comply; add assertion/test)
- [x] 2.4 Tests (RED→GREEN) in `scripts/generate-operation-schemas.spec.ts` and `scripts/templates/account-schema.spec.ts`: never-persisted field fails codegen; fully-persisted passes; `persist-dynamic` marker whitelists; response summary field excluded from account schema — covers templates-generator "Persist-output guard" and "Account schema generation" scenarios

## 3. Remediate operations (audit all; fix violators)

- [x] 3.1 Audit every `src/operations/*/index.ts`: classify each `output` field as persisted vs response-only (confirmed violator: `access-model-sod-remediation`; confirm `example`, `governance-group-emails`, `preventive-sod-check`, `sod-remediation`, `access-model-sod-remediation-apply` are compliant)
- [x] 3.2 Refactor `src/operations/access-model-sod-remediation/index.ts`: move scan-summary counters (`access-items-scanned`, `violations-found`, `forms-skipped`, `forms-skipped-instances`, `forms-launch-failed`, `forms-persist-failed`) from `output` into `response`; keep only persisted child keys in `output`; replace `ctx.res.send({...})` with `ctx.respond({...summary})`
- [x] 3.3 Regenerate `*.schema.ts` sidecars, `src/operations/auto-registry.ts`, and `connector-spec.json` via `npm run codegen:schemas`; confirm the account schema no longer contains scan-summary counters
- [x] 3.4 Update `src/operations/access-model-sod-remediation/index.spec.ts` and the persist-output guard fixtures — covers connector-operations "Access model scan summary on invoke response" scenarios

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 Run `npm run typecheck`, `npm test`, `npm run codegen:schemas` (guard passes), `npm run build`
- [x] 4.3 All delta spec scenarios covered by named automated tests across framework, codegen, and access-model operation specs

## 5. Documentation

- [x] 5.1 Update `src/operations/_template/README.md` + `src/operations/_template/index.ts` to demonstrate persisted-only `output`, `response`, and `ctx.respond`
- [x] 5.2 Update the generated workflow-invocation guidance/README notes for the operation response envelope (`name`/`status`/`responses`/`summary`)
- [x] 5.3 Update JSDoc on `OperationSignature`, `OperationResponse`, `RequestContext`, and `ctx.respond` describing the output↔persist / response↔res.send split

## 6. Changelog

- [x] 6.1 Create or update the changelog entry for this change (persisted-output contract, response envelope, codegen guard, access-model remediation)
- [x] 6.2 Confirm the entry covers the user-visible contract change (account schema shrinks to persisted attributes; typed `ctx.res.send` envelope)
