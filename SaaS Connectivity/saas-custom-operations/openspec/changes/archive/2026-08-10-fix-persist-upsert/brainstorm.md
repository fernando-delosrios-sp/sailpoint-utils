# Brainstorm: Fix Persist Upsert

## Background

`ctx.persist(id, attributes?, status?, options?)` writes custom-operation output to the ISC result source as dummy accounts. Implementation lives in `src/framework/persist-result.ts` and is wired in `request-context.ts` via `createAccountV1`.

The spec and README document **upsert semantics**: re-persisting the same identity should overwrite the prior result. The existing scenario "Persist upserts duplicate identity" expects `ctx.persist('req-001', …)` to succeed when an account with that identity already exists.

In practice, local `npm run debug` / `spcx` runs that reuse the same `requestId` fail when a prior invocation already created the account. `createAccountV1` does not reliably update an existing native identity on this source type — duplicate creates error or leave stale attributes, breaking debug iteration and any workflow retry that re-persists the same identity.

`sailpoint-api-client` exposes `putAccountV1({ id, accountAttributes })` for updating an existing ISC account record (requires the ISC account UUID, not nativeIdentity).

## Problem statement

Persist always calls `createAccountV1`. When the result account already exists (common when re-running debug with the same `requestId`, or after a partial failure + retry), the write path fails or does not update attributes. Developers cannot iterate locally without manual account cleanup.

## Decision chain

### Q1: How should upsert choose create vs update?

**Options considered:**

| Approach | Pros | Cons |
|---|---|---|
| A. Probe-first: `listAccountsV1` → create or put | Predictable; no reliance on create error semantics | Extra read on every persist (first write pays one list) |
| B. Create-first, catch conflict → put | No read on happy path for new identities | Error-driven control flow; conflict detection fragile across API versions |
| C. Always put (requires pre-existing account) | Simple | First persist always fails — unacceptable |

**Decision:** A — probe-first. `listAccountsV1` filtered by `nativeIdentity` and `sourceId` is already used by `readAccount`; extend lookup to return ISC account `id` when present, then branch.

### Q2: What API for update?

**Decision:** `putAccountV1` with the ISC account UUID from list response and `accountAttributes.attributes` matching create payload shape.

### Q3: Where does branching live?

**Options:**

| Approach | Pros | Cons |
|---|---|---|
| A. Single `upsertAccount` in `PersistDependencies` | `createPersist` stays API-agnostic; easy to test | Wiring complexity in `request-context.ts` |
| B. Branch inside `createPersist` with separate deps | More explicit in persist module | Persist layer needs create + update + find |

**Decision:** A — replace `createAccount` with `upsertAccount(attributes)` (or add `updateAccount` + keep create, invoked from a composite). Tests mock one write function.

### Q4: Does verification behavior change?

**Decision:** No. Default inline verify and `verifyPersisted` retry read-back unchanged. Upsert must still pass type-aware comparison after update.

### Q5: Test mode impact?

**Decision:** None. Test mode inhibits all ISC writes; signatures unchanged.

### Q6: Spec / manifest changes?

**Decision:** Update `custom-operation-framework` requirement text and upsert scenario to name `putAccountV1` for updates. Update `target-client` persist scenario to mention create + update APIs. No `connector-spec.json` change.

## Trade-offs

- **Extra list call per persist:** Acceptable — persist is low-frequency (typically 1–few per invocation); correctness beats saving one HTTP round-trip.
- **Account id lookup coupling:** `putAccountV1` needs ISC internal id; list response must expose it. Mitigation: typed lookup helper; fail clearly if account exists but id missing.
- **Async indexing lag:** Update may still need read-back retry (existing behavior).

## Success criteria

1. Second `ctx.persist` with same identity updates attributes via `putAccountV1` without error
2. First persist for new identity still uses `createAccountV1`
3. Re-running local debug with same `requestId` succeeds after prior successful persist
4. `npm test` passes with explicit upsert scenario coverage (create vs update mocks)
5. Spec scenario "Persist upserts duplicate identity" maps to automated test

## Open questions (deferred)

- Whether to cache account id within a single invocation after first lookup (optimization; defer)
- Exact HTTP status from failed duplicate create in tenant (motivates probe-first regardless)
