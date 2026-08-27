## Scope

Move access-model-sod-remediation scan rollup counts from a persisted parent result-source account on `requestId` into the invoke response via `ctx.res.send`. Child accounts at `{requestId}:{accessItemId}:{policyId}` remain unchanged. Out of scope: violation detection, form launch, child persist fields, dual-write of parent rollup, or changes to `custom:sod-remediation`.

## Language

**Scan summary** (`promote`):
Rollup counts from a successful `custom:access-model-sod-remediation` invoke: `access-items-scanned`, `violations-found`, and optional `forms-skipped` / `forms-persist-failed`. Delivered on the command response via `ctx.res.send`, not as a result-source account on `requestId`.
_Avoid_: parent account, summary account, rollup account (when referring to the invoke response payload)

**Child persist identity** (`draft`):
Result-source account id `{requestId}:{accessItemId}:{policyId}` holding per-form workflow outputs (`form-url`, `form-email-*`). Unchanged by this change.
_Avoid_: child account (acceptable in workflow docs; prefer child persist identity in normative spec text)

**Parent persist rollup** (`conflicts-with-canonical`):
Current behavior: upsert on `requestId` with scan counters. Removed by this change; canonical spec still describes it until archived.
_Avoid_: continuing to persist rollup on `requestId`

## Decisions

**Context:** Workflows today read rollup counts from Get Accounts on `requestId`; child accounts hold per-form email fields.

**Q1 — Where do rollup fields live after the change?**
→ Chosen: `ctx.res.send({ status: 'success', ...prefixed rollup fields })`. Same `access-model-sod-remediation:*` key names as today for minimal workflow JSONPath churn on the invoke step.

**Q2 — Do child accounts still persist?**
→ Chosen: Yes. Only the parent/summary account on `requestId` is removed.

**Q3 — Are rollup fields still on OperationSignature.output / account schema?**
→ Chosen: Keep typed output keys for codegen and documentation, but they apply to the invoke response payload only—not to any persisted account attribute on `requestId`. Child-only fields (`form-url`, `form-email-*`) remain on child persist only.

**Q4 — What about `forms-skipped` / `forms-persist-failed` during the scan loop?**
→ Chosen: Accumulate in handler state; include in final `res.send` when > 0 (same optional semantics as today).

**Q5 — Duplicate invoke / in-flight dedupe?**
→ Chosen: No change to framework dedupe (still returns `{ status: 'success' }` without replaying summary). Document as known limitation; out of scope to enrich dedupe response.

## Open questions

None — user request is explicit.

## Scenarios discussed

- Scan completes with zero violations: `res.send` includes `access-items-scanned` and `violations-found: 0`; no child accounts; no account on `requestId`.
- Scan hits form cap: rollup in `res.send` reflects counts at cap; children persist for forms created before cap.
- Idempotent skip: `forms-skipped` increments in `res.send` summary only (no parent persist).
- Child persist failure: `forms-persist-failed` in `res.send`; child persist errors still logged; scan continues.
- Offline / test mode: `res.send` carries summary; child persist inhibited in test mode per existing framework behavior.
- Workflow migration: invoke step must read rollup from connector response body instead of Get Accounts on `requestId`; child notification loop unchanged.
