## Why

`OperationSignature.output` is the single source of truth for the result-source account schema, yet authors declare `ctx.res.send` rollup counters (e.g. `access-items-scanned`, `forms-created`) in it. Those keys are never persisted, so codegen propagates them into the account schema as attributes that appear on no account — schema pollution and drift. `access-model-sod-remediation` on `main` and abb's `access-expiration-reminders` both show it. The glossary already calls these counters a **scan summary** that is *not persisted*, but nothing structurally keeps them out of `output`. Fixing the contract now prevents every new operation from replicating the defect.

## What Changes

**Meaning of `OperationSignature.output`**
- From: catch-all for persisted attributes *and* `ctx.res.send` summary content.
- To: persisted attributes only — exactly the keys any `ctx.persist(...)` call writes; the sole feed for the account schema.
- Reason: the account schema must mirror what is actually persisted.
- Impact: breaking for operations that listed summary counters in `output`; those keys move to the response envelope.

**Typed operation response envelope**
- From: `ctx.res.send({...})` payload is untyped and overlaps `output`.
- To: a distinct typed contract on the signature — `name`/`type`, `status`, `responses` (the persisted native ids of the invoke), plus per-operation summary detail. Not propagated to the account schema.
- Reason: give the res.send summary its own home so it cannot leak into `output`.
- Impact: new signature surface; `status`/`responses` framework-populatable from the persist registry.

**Codegen persist-output guard**
- From: codegen copies every `output` field into the schema with no validation.
- To: codegen/lint fails when an `output` field is never persisted, or when a response-envelope-only key leaks into `output`/the account schema.
- Reason: enforce the contract mechanically so regressions fail the build.
- Impact: non-breaking once operations comply; failing build for current violators until fixed.

**Remediate all `main` violators**
- Audit every operation; move res.send-only counters out of `output` into the response envelope. Confirmed violator: `custom:access-model-sod-remediation`.

## Capabilities

### New Capabilities
- (none — reuse existing capabilities)

### Modified Capabilities
- `custom-operation-framework`: redefine the operation-signature `output` as persisted-only; add the typed operation response envelope; clarify base account schema derives from persisted output only.
- `templates-generator`: account schema and sidecar codegen derive from persisted output only; add the persist-output guard that fails on never-persisted `output` fields.
- `connector-operations`: `access-model-sod-remediation` output signature carries only persisted child attributes; scan-summary counters move to the response envelope.
- `ubiquitous-language`: promote **operation response** and **response id list**; reconcile **scan summary** as the access-model instance of the general response envelope.

## Impact

- **Code:** `src/framework/types.ts` (`OperationSignature`, `RequestContext`, response envelope typing), `src/framework/output-schema.ts`, `src/framework/persist-result.ts` (persist registry → `responses`), `scripts/generate-operation-schemas.ts` + `scripts/templates/operation-introspection.ts` + `scripts/templates/account-schema.ts` (guard + derivation), and operation `index.ts` files (starting `access-model-sod-remediation`) with regenerated `*.schema.ts` sidecars and `connector-spec.json`.
- **Contracts:** result-source **account schema** shrinks to persisted attributes only; `ctx.res.send` payload becomes typed. Workflow readers that keyed off never-persisted schema attributes were already reading nothing.
- **Verification:** `npm run typecheck`, `npm test`, `npm run codegen:schemas`, `npm run build`.
