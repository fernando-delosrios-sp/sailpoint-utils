## Why

Custom operations persist workflow results to a dummy ISC source via `ctx.persist()`, but the helper returns as soon as `createAccountV1` accepts the request. That API is asynchronous — it returns a task id, not the written account — so operations can complete while the account is missing or has wrong attributes. Workflows then proceed on false confidence that results were stored. Read-back verification before returning control closes this gap. An opt-out and batch verify helper support multi-write operations that defer verification to a single checkpoint.

## What Changes

**Persist helper verification (default on)**
- From: `persist()` calls account create, logs, and resolves immediately
- To: `persist()` verifies read-back by default; optional `{ verify: false }` skips inline verification; written expectations are recorded either way
- Reason: Safe default with deferred verification for multi-write flows
- Impact: Backward compatible extension — existing 3-arg calls verify by default; new 4th options arg for opt-out

**Batch verification on context**
- From: No author-facing verify API beyond inline persist
- To: `ctx.verifyPersisted(ids: string[])` reads and verifies a list of identities written earlier in the same invocation
- Reason: Lets operations batch-write then verify once before completing
- Impact: New RequestContext method; operations using deferred verify must call it explicitly

**Framework dependencies**
- From: `PersistDependencies` exposes only `createAccount`
- To: `PersistDependencies` also exposes `readAccount(id)`; context holds a write registry mapping identity → expected attributes
- Reason: Shared read/compare logic for inline and batch paths; testable via mocks
- Impact: Internal framework change plus two author-facing API extensions

## Capabilities

### New Capabilities

<!-- None — extending existing custom-operation-framework capability -->

### Modified Capabilities

- `custom-operation-framework`: Extend "Result persistence helper" with default read-back verification, optional `{ verify: false }` opt-out, write registry, and new `verifyPersisted(ids)` batch verification requirement

## Impact

- `src/framework/persist-result.ts` — verification logic, write registry, `createVerifyPersisted`
- `src/framework/types.ts` — `PersistOptions`, extended `PersistFn`, `VerifyPersistedFn`, extended `RequestContext`, extended `PersistDependencies`
- `src/framework/request-context.ts` — wire `readAccount`, attach `verifyPersisted` and write registry to context
- `src/framework/persist-result.spec.ts` — tests for inline verify, opt-out, batch verify, registry miss
- `src/framework/index.ts` — export new types and error class
- `connector-spec.json` — no changes
- Operation author templates — document opt-out and `verifyPersisted` usage pattern
