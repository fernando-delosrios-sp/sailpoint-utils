## Context

`custom:access-model-sod-remediation` detects intrinsic SoD violations and launches standalone forms for policy owners. Per-violation workflow outputs persist on child result-source identities `{requestId}:{accessItemId}:{policyId}`. The prior change (`access-model-sod-request-scoped-form-dedupe`) keyed idempotency on ASSIGNED form instances matching `formInput.parentRequestId`. Operators running concurrent or retried scans with partial progress need idempotency tied to persisted child accounts instead.

## Goals / Non-Goals

**Goals:**
- Skip form launch and child persist when the child account already exists for the violation key.
- Remove form-instance search from the scan dedupe path.
- Preserve offline bypass (no account lookup in test/offline mode).
- Update specs, tests, README, and changelog to match.

**Non-Goals:**
- Changing apply idempotency (`custom:access-model-sod-remediation-apply`).
- Removing `formInput.parentRequestId` from launched forms.
- Backfilling or deleting legacy child accounts or form instances.
- Changing child persist identity pattern or output field names.

## Decisions

### D1: Idempotency signal is child persist account existence

- **Choice:** Before creating a form, call `findAccountOnSource(ctx.sdk.accounts, ctx.sourceId, childPersistIdentity(...))`. If found, increment `forms-skipped` and `continue`.
- **Reason:** Child accounts are what downstream workflows read; they survive form state transitions.
- **Considered alternatives:** Keep form-instance dedupe as secondary check — rejected; user explicitly requested forgetting form instances.

### D2: Skip both form creation and persist on match

- **Choice:** Early `continue` before `createAccessModelSodRemediationInstance` and `ctx.persist`.
- **Reason:** Avoid duplicate forms and putAccount overwrites on concurrent retries.
- **Considered alternatives:** Skip form only, still persist — rejected; would overwrite or fail.

### D3: Remove form-instance dedupe module surface

- **Choice:** Delete `hasAssignedRemediationInstance`, cache helpers, and related tests from `form-service.ts`.
- **Reason:** Dead code after D1; reduces ISC API surface and maintenance.
- **Considered alternatives:** Keep helpers unused — rejected.

### D4: Offline unchanged

- **Choice:** Skip account lookup when `isOfflineContext(ctx)`; proceed with offline fixtures.
- **Reason:** Matches prior form-dedupe bypass; no result source in test mode.

## Risks / Trade-offs

- [Risk] Orphan ASSIGNED form without child account (launch succeeded, persist failed) → retry creates duplicate form.  
  → Mitigation: Accept; `forms-persist-failed` counter already surfaces partial failures; operators can reconcile manually.

- [Risk] Child account exists from manual/test data without intended form → skip blocks new form.  
  → Mitigation: Child key is deterministic; delete errant account or use new `requestId`.

- [Trade-off] Per-violation account lookup vs one form search per scan.  
  → Accept: lookup is cheap relative to form create; correctness outweighs batch search optimization.

## Migration Plan

1. Ship code + spec delta (implementation largely present in working tree).
2. Update README scan performance section — remove form search note; document child-account skip.
3. Add CHANGELOG PATCH entry describing idempotency behavior change.
4. No connector-spec.json or output schema changes.
5. Rollback: revert to form-instance dedupe implementation and spec.

## Open Questions

None.
