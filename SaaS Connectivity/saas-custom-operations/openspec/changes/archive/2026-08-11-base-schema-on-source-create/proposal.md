# Proposal: Base schema on result source create

## Why

When the framework auto-creates a DelimitedFile result source, it applies only three core account attributes (`id`, `status`, `date`) or leaves an ISC-discovered schema in place. Operation output fields appear only after each operation's first `ctx.persist`, so the live source schema lags behind the generated `account-schema.json` reference. Operators expect a complete schema at source creation; applying the base schema immediately removes first-run patch churn and aligns runtime behavior with templates.

## What Changes

**Account schema on new source create**
- From: `createDelimitedFileResultSource` creates `DEFAULT_RESULT_ACCOUNT_SCHEMA` (core attrs only)
- To: After source create, apply the **base account schema** — core attrs plus union of all registered operation output fields with typed inference
- Reason: Match templates reference schema and ISC admin expectations on first use
- Impact: Non-breaking; only affects newly auto-provisioned result sources

**Existing schema on create path**
- From: Unconditional `createAccountSchema` with minimal payload; may conflict or diverge if ISC already discovered a schema
- To: Read account schema after create; create or patch to base schema (add-only attribute alignment, same type/isMulti conflict policy as persist reconciliation)
- Reason: "Replace current account schema with base schema" when DISCOVER_SCHEMA pre-populates the source
- Impact: Non-breaking

**Shared schema builder**
- From: Templates `buildAccountSchema` and framework `DEFAULT_RESULT_ACCOUNT_SCHEMA` are separate
- To: Shared base-schema builder used by templates generator and source create path
- Reason: Single inference source of truth
- Impact: Non-breaking internal refactor; generated `account-schema.json` unchanged in shape

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `custom-operation-framework`: New requirement for base account schema application when auto-provisioning a result source; update missing-source scenario to expect full base schema instead of core-only default

## Impact

- **Code:** `src/framework/result-source.ts`, `src/framework/operation-schema-registry.ts`, shared base-schema builder; templates `account-schema.ts` import path
- **APIs:** Additional `getSourceSchemasV1` / `createSourceSchemaV1` / `updateSourceSchemaV1` calls on source create path only
- **Tests:** `result-source.spec.ts`, registry helper tests, templates parity test
- **Docs:** README note that auto-created sources receive full base schema
- **Operational:** Existing result sources unchanged; delete/recreate source or manual schema edit if operators want re-baseline
