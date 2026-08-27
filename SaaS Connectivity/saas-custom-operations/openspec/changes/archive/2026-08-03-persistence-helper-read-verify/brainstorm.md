# Brainstorm: Persistence Helper Read-Back Verification

Raw capture of design exploration for adding a read-after-write safety mechanism to the `ctx.persist()` helper.

## Background

The custom-operation foundation (`src/framework/persist-result.ts`) exposes `persist(id, params?, status?)` which writes operation results to a dummy ISC source via `createAccountV1`. Today the helper:

1. Builds account attributes (id, date, status, param1..param9)
2. Calls account create (upsert semantics)
3. Logs and returns immediately

`createAccountV1` returns an `AccountsAsyncResult` (async task id), not the persisted account. The custom operation receives control back without confirmation that ISC actually stored the expected attributes. Silent write failures or async lag could leave workflows believing results were persisted when they were not.

## Decision Chain

### Q1: What problem are we solving?

**Decision:** Guarantee that persisted results are verifiable before an operation completes — either inline per `persist()` call or in a deferred batch.

**Rationale:** Custom operations drive ISC workflows; false-positive persist success is worse than a surfaced error the workflow can handle.

### Q2: When should verification happen?

**Decision:** Verification runs by default on every `persist()` call. Authors MAY opt out per call via an optional options parameter (`{ verify: false }`). Authors MAY defer verification for multiple writes and run batch verification via `ctx.verifyPersisted(ids)` before the handler completes.

**Rationale:** Default-safe behavior with escape hatches for multi-write operations that want to verify once at the end (reducing API round-trips).

**Considered alternatives:**
- Opt-in only (`{ verify: true }`) — rejected; safety off by default
- No batch helper — rejected; user requested explicit ctx function for id lists

### Q3: How do we read the account back?

**Decision:** Add a `readAccount(id)` dependency injected alongside `createAccount`. Runtime wiring uses `listAccountsV1` filtered by `nativeIdentity eq "{id}" and sourceId eq "{sourceId}"`, returning the first match's attributes.

**Rationale:** Matches existing SDK loopback pattern; keeps verification testable with mocked read/create callbacks.

### Q4: What constitutes a successful verification?

**Decision:** Read-back account MUST exist and its attributes MUST match all values the helper wrote: `status`, `date`, and each `paramN` that was set (sparse params — unset slots are not compared).

**Rationale:** Confirms the full payload landed; sparse comparison avoids false failures on omitted param slots.

### Q5: How do we handle async create lag?

**Decision:** Bounded retry with short fixed delay (up to 5 attempts, 200ms apart) before failing verification.

**Rationale:** `createAccountV1` is async; immediate read may return empty.

### Q6: What happens on verification failure?

**Decision:** `persist()` and `verifyPersisted()` reject with `PersistVerificationError`. Framework does not swallow errors.

### Q7: Public API shape

**Decision:**
- Extend `PersistFn` to `persist(id, params?, status?, options?)` where `options.verify` defaults to `true`
- Add `VerifyPersistedFn` as `verifyPersisted(ids: string[])` on `RequestContext`
- Framework tracks expected attributes per identity written during the invocation (in-memory registry on context) so batch verify knows what to compare

**Rationale:** Opt-out is explicit; batch verify reuses the same comparison logic and stored write expectations.

### Q8: Batch verify behavior for unknown ids

**Decision:** `verifyPersisted(ids)` SHALL only verify identities previously written via `ctx.persist()` in the same invocation. Requesting an id not in the registry SHALL reject with a descriptive error.

**Rationale:** Without stored expectations, attribute comparison is undefined; existence-only would be a weaker contract.

## Trade-offs Accepted

| Trade-off | Acceptance |
|---|---|
| Extra ISC API call(s) per persist when verify=true | Acceptable — default safe; batch path reduces calls when opted out |
| In-memory write registry per invocation | Acceptable — volatile context scope; discarded after handler completes |
| PersistFn signature extended with optional 4th arg | Acceptable — backward compatible; existing 3-arg calls verify by default |

## Validated Design Summary

```
persist (verify=true, default):
  build attributes → createAccount → record expected → retry readAccount → compare → resolve or reject

persist (verify=false):
  build attributes → createAccount → record expected → resolve

verifyPersisted(ids):
  for each id in ids → lookup expected from registry → retry readAccount → compare → resolve or reject
```

Example author usage:

```typescript
await ctx.persist(ctx.requestId, [summary], undefined, { verify: false })
await ctx.persist(`${ctx.requestId}:detail`, [summary, '1'], undefined, { verify: false })
await ctx.verifyPersisted([ctx.requestId, `${ctx.requestId}:detail`])
```
