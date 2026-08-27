## Context

The custom-operation foundation provides `ctx.persist(id, params?, status?)` which writes operation output as dummy accounts on a tenant source via ISC account create (upsert). Implementation lives in `src/framework/persist-result.ts` and is wired in `request-context.ts`.

`createAccountV1` returns `AccountsAsyncResult` (async provisioning task), not the persisted account record. The current helper treats a successful create response as completion.

Exploration (brainstorm.md) validated: verification on by default, optional opt-out per persist call, batch `verifyPersisted(ids)`, injectable read callback, in-memory write registry per invocation, attribute-level comparison, bounded retry, and fail-loud error propagation.

## Goals / Non-Goals

**Goals:**
- `persist()` verifies read-back by default before resolving
- Authors MAY opt out inline verification via `{ verify: false }` on individual persist calls
- Authors MAY call `ctx.verifyPersisted(ids)` to verify multiple deferred writes before handler completes
- Framework records expected attributes for every persist in the invocation
- Surface verification failures as rejected promises with actionable error messages

**Non-Goals:**
- Changing the dummy source schema or connector-spec.json
- Verifying ISC system attributes beyond what the helper writes (status, date, param1..param9)
- Polling provisioning task status via the async task id from create
- Author-configurable retry/timeout knobs (use sensible framework defaults)
- Cross-invocation verification (registry is volatile, scoped to one handler run)

## Decisions

### D1: Default verification with opt-out

- **Choice:** `options.verify` defaults to `true`; `{ verify: false }` skips inline read-back but still records expected attributes in the write registry
- **Reason:** Safe default; opt-out supports multi-write-then-verify pattern
- **Considered alternatives:** No opt-out (rejected — user requested it); opt-in only (rejected — safety off by default)

### D2: Batch verification via ctx.verifyPersisted

- **Choice:** Add `verifyPersisted(ids: string[]): Promise<void>` to `RequestContext`; verifies each id against registry expectations using shared read/compare/retry logic
- **Reason:** Explicit checkpoint for deferred verification; reuses same contract as inline verify
- **Considered alternatives:** Auto-verify all registry entries at handler exit (rejected — implicit, hides failures until end without author control)

### D3: Write registry on context

- **Choice:** In-memory `Map<string, Record<string, string>>` on the request context, populated on every persist with the built attributes; latest write wins for duplicate identity
- **Reason:** Batch verify needs expected values; scoped to invocation lifecycle
- **Considered alternatives:** Re-build expectations from params at verify time (rejected — date timestamp would differ from write time)

### D4: Read via listAccountsV1 filter

- **Choice:** Runtime `readAccount` uses `listAccountsV1({ filters: 'nativeIdentity eq "{id}" and sourceId eq "{sourceId}"' })` and returns attributes from the first match
- **Reason:** Create returns task id, not account id; nativeIdentity is the identity authors pass to persist

### D5: Attribute comparison scope

- **Choice:** Compare `status`, `date`, and each `paramN` present in the recorded expected attributes; ignore extra ISC attributes
- **Reason:** Validates the helper's contract without brittle full-map equality

### D6: Bounded retry for async lag

- **Choice:** Up to 5 read attempts with 200ms fixed delay between attempts (~1s max wait), shared by inline and batch verify
- **Reason:** `createAccountV1` is async; immediate read may return empty

### D7: Error propagation

- **Choice:** `PersistVerificationError` when account missing after retries, attributes mismatch, or id not in write registry during batch verify
- **Reason:** Fail loud; workflows see operation failure

### D8: PersistFn signature extension

- **Choice:** `persist(id, params?, status?, options?: PersistOptions)` where `PersistOptions = { verify?: boolean }`
- **Reason:** Backward compatible — existing 3-arg calls unchanged in behavior (verify defaults true)
- **Considered alternatives:** Separate `persistWithoutVerify` method (rejected — splits API surface)

### D9: Batch verify for unknown ids

- **Choice:** `verifyPersisted` rejects if any requested id was not written via persist in the current invocation
- **Reason:** Attribute expectations are undefined without a registry entry

## Risks / Trade-offs

- [Risk] Authors forget to call `verifyPersisted` after opt-out writes → Mitigation: document pattern in template/JSDoc; default verify=true requires no action for simple flows
- [Risk] Extra API calls when verify=true on every persist → Mitigation: opt-out + batch path for high-volume writes
- [Risk] listAccounts filter syntax differs across API versions → Mitigation: use pinned sailpoint-api-client; mock in tests
- [Trade-off] 4th optional arg on persist → Accepted: minimal extension, backward compatible

## Migration Plan

1. Extend types with `PersistOptions`, `VerifyPersistedFn`, write registry
2. Implement shared verify logic and `createPersist` / `createVerifyPersisted` factories
3. Wire both on `RequestContext` in `request-context.ts`
4. Add unit tests for default verify, opt-out, batch verify, registry miss
5. Run `npm test` and `npm run build`

Existing 3-arg `ctx.persist(...)` calls gain verification automatically (behavior change). Authors needing fire-and-forget must explicitly pass `{ verify: false }` and follow with `verifyPersisted`.

## Open Questions

- None — user refinements incorporated (opt-out + batch verify).
