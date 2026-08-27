## Context

The custom-operation framework persists workflow results to an ISC DelimitedFile result source via `ctx.persist`. Wiring in `request-context.ts` delegates all writes to `createAccountV1`. The main spec documents upsert semantics and includes a scenario for re-persisting an existing identity, but local debug runs reusing the same `requestId` fail when a prior invocation already created the account.

`sailpoint-api-client` provides `putAccountV1({ id, accountAttributes })` for updating existing accounts. Updates require the ISC account UUID from `listAccountsV1`, not the native identity used as persist id.

## Goals / Non-Goals

**Goals:**

- Implement probe-first upsert: create when absent, update when present
- Preserve existing attribute formatting, schema reconciliation, and read-back verification
- Add Vitest coverage distinguishing create vs update paths
- Align spec scenarios with actual ISC API usage

**Non-Goals:**

- Caching account IDs across invocations within one operation (defer optimization)
- Changing test mode inhibited-write behavior
- Changing verify retry budgets or ConnectorError handling
- Modifying connector-spec.json or adding commands

## Decisions

### D1: Probe-first upsert

- **Choice:** Before write, look up account via `listAccountsV1` filtered by `nativeIdentity eq "{id}" and sourceId eq "{sourceId}"`. If a record exists with an ISC account id, call `putAccountV1`; otherwise call `createAccountV1`.
- **Reason:** Predictable behavior without relying on duplicate-create error codes, which may vary by tenant or source type.
- **Alternatives considered:** Create-first with conflict catch (rejected — fragile); always put (rejected — first write fails).

### D2: Composite write dependency

- **Choice:** Replace `PersistDependencies.createAccount` with `upsertAccount(attributes)` implemented in `request-context.ts` (or add `findAccountByNativeIdentity` + separate create/update deps composed in persist layer).
- **Reason:** Keeps `createPersist` testable with a single mock write function; concentrates ISC API knowledge in wiring layer.
- **Alternatives considered:** Branch inside `createPersist` with three separate deps (acceptable but noisier tests).

### D3: Account lookup returns id + attributes

- **Choice:** Extend list lookup helper to return `{ iscAccountId, attributes } | undefined` so upsert and read-back share filter logic.
- **Reason:** `putAccountV1` requires ISC UUID; `readAccount` today returns attributes only.
- **Alternatives considered:** Second list call in update path (rejected — duplicate HTTP).

### D4: Verification unchanged

- **Choice:** After upsert, run existing `verifyAccountWrite` / read-back retry unchanged.
- **Reason:** Update is async like create; existing retry semantics already handle indexing lag.

### D5: Error on missing account id

- **Choice:** If list returns a match without `id`, throw a clear error (wrapped as `ConnectorError` at boundary if thrown from persist path).
- **Reason:** Cannot call `putAccountV1` without UUID; silent fallback to create would duplicate.

## Risks / Trade-offs

- [Risk] Extra `listAccountsV1` on every persist → Mitigation: acceptable for low-frequency writes; optional per-invocation cache deferred
- [Risk] List returns stale empty during indexing after create → Mitigation: existing read-back retry already handles post-write lag; probe runs before write not after
- [Trade-off] Probe-first adds latency vs create-only → Accepted for correctness on debug re-runs and retries

## Migration Plan

N/A — connector package-only change. Deploy via `npm run build` + `spcx package`. Rollback: revert connector version. No tenant migration.

**Verification after deploy:**

1. Run operation locally twice with same `requestId` — second run should succeed and update attributes
2. Confirm first persist on new identity still creates account

## Open Questions

- Whether to cache `{ nativeIdentity → iscAccountId }` within a single invocation after first lookup (defer unless profiling shows issue)
