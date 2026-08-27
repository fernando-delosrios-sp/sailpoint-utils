## Why

Workflows that read custom operation outcomes from the DelimitedFile result source can see `status`, `date`, and `details`, but not which custom command wrote the account. That makes multi-operation result stores harder to filter and debug, and obscures which handler produced a row when the same `requestId` is retried or overwritten. A framework-managed `operationName` attribute on the base schema—auto-populated from the invocation command—gives workflows a stable, operation-agnostic field without asking each handler to persist it manually.

## What Changes

**operationName core schema attribute**
- From: Base schema core attributes are `id`, `status`, `date`, and `details`.
- To: Base schema includes mandatory STRING attribute `operationName` alongside existing core attributes.
- Reason: Workflows need the invoking custom command on every result account.
- Impact: Non-breaking; existing sources gain `operationName` on next schema reconciliation.

**Automatic operationName on persist**
- From: Persist always sets `id`, `date`, and `status`; handlers may set optional `details`.
- To: Persist always sets `operationName` from `context.commandType` when available; author-supplied `operationName` in persist attributes is ignored.
- Reason: Consistent population without per-handler boilerplate.
- Impact: Non-breaking additive account field.

**Failure and test-mode paths**
- From: Automatic failed-account persist sets `status` and `details`.
- To: Same paths also set `operationName` when command context is available.
- Reason: Failures should be attributable to the invoked command in Get Accounts reads.
- Impact: Non-breaking.

## Capabilities

### New Capabilities

_(none — behavior extends existing framework capability)_

### Modified Capabilities

- `custom-operation-framework`: Add `operationName` core attribute; auto-populate on persist and failure persist; update base schema and reconciliation requirements
- `operation-test-runner`: Inhibited-persist / payload summaries reflect `operationName` when automatic persist runs

## Impact

- **Framework:** `base-account-schema.ts`, `persist-result.ts`, `result-source.ts`, `request-context.ts` / `createPersist` wiring, `failure-persist.ts`, `test-mode-persist.ts`, `output-schema.ts` reserved keys
- **Tests:** `base-account-schema.spec.ts`, `persist-result.spec.ts`, `result-source.spec.ts`, `with-custom-operation.spec.ts`, `test-mode-persist.spec.ts`, `call-op.spec.ts` / payload output if applicable
- **Templates:** `scripts/templates/account-schema.spec.ts` (via shared `buildBaseAccountSchema`)
- **Docs:** Root README framework/persist section; CHANGELOG
