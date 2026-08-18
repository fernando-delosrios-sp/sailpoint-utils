## Scope

**In:** Replace access-model SoD scan idempotency from ASSIGNED form-instance search to child result-source account lookup. Before launching a form for a violation, skip when a child account already exists at `{requestId}:{accessItemId}:{policyId}` — no form creation, no persist overwrite. Remove `searchFormInstancesByTenantV1` dedupe path and related helpers.

**Out:** Changes to `custom:access-model-sod-remediation-apply`, form seed / `parentRequestId` on instances, workflow orchestration, or backfilling legacy child accounts.

## Language

**child persist identity** (`promote`):
The result-source native identity `{requestId}:{accessItemId}:{policyId}` where per-violation scan outputs (`form-url`, `form-email-*`) are persisted after a form is launched.
_Avoid_: child account (acceptable in workflow docs; prefer in normative spec text)

**child persist account idempotency** (`promote`):
Skipping form launch and child persist when `findAccountOnSource` finds an existing account on the result source for the child persist identity of the current violation — regardless of form instance state.
_Avoid_: request-scoped form dedupe, pending form dedupe

**forms-skipped** (`conflicts-with-canonical`):
Rollup counter on scan invoke response. Canonical text ties this to ASSIGNED duplicate forms; after this change it counts violations skipped because the child persist account already exists.
_Avoid_: forms-created

**parent request id** (`promote`):
The `requestId` on a `custom:access-model-sod-remediation` invoke. It prefixes child persist identities; still stored on form instances as `formInput.parentRequestId` but no longer drives scan idempotency.
_Avoid_: parentRequest, scanId

## Decisions

**Context:** Concurrent or retried scans with the same `requestId` can race: some child accounts and forms already exist while others do not. Form-instance dedupe (ASSIGNED + `parentRequestId` match) misses cases where a child account was persisted but the form moved to SUBMITTED/COMPLETED, and adds an extra ISC search per scan.

**Q1 — What signal means "already handled for this violation"?**
→ Existing child result-source account at `{requestId}:{accessItemId}:{policyId}`.

**Q2 — Skip persist as well as form creation?**
→ Yes. Do not overwrite an existing child account on retry/concurrency.

**Q3 — Form instance state relevant?**
→ No. Do not query form instances for idempotency.

**Q4 — Offline / test mode?**
→ Unchanged: skip account lookup in offline context (same as prior form dedupe bypass).

**Q5 — Different `requestId` for same access item + policy?**
→ Different child persist identity → new form may be created (unchanged from child-key model).

## Open questions

None — scope locked by user request and partial implementation in working tree.

## Scenarios discussed

- **Retry same scan:** Child accounts exist for 2/3 violations → skip those, create form only for the remaining violation; increment `forms-skipped` for skipped count.
- **Concurrent invokes same `requestId`:** First writer persists child account; second invoke skips that violation without duplicate form or putAccount.
- **Prior form submitted, child account remains:** Skip on retry (behavior change vs ASSIGNED-only form dedupe).
- **Child account missing, ASSIGNED form exists:** Create form and persist (behavior change — form alone no longer blocks).
- **Offline invoke:** No account lookup; forms created per offline fixtures as today.
