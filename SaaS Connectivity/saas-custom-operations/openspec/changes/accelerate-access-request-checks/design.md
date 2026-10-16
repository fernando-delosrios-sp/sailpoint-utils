## Context

Both evaluators are dominated by ISC round-trips. Risk scoring walks roles → access profiles → entitlements one at a time. Preventive SoD searches events per executing grant, expands each access item, then in request mode expands overlapping sets twice and runs two predict calls back-to-back. The pre-check workflow adds a second serial invoke plus account-index waits. Persistence verification remains correct for standalone callers; the new combined command is the fast path for the deadline-bound trigger.

## Goals / Non-Goals

**Goals:**

- Bound concurrent ISC reads so independent work overlaps without stampeding the tenant.
- Deduplicate in-flight catalog and entitlement-expansion lookups within one invocation.
- Collapse the bundled pre-check to one invoke whose HTTP `summary` carries both verdicts.
- Keep standalone risk and SoD command contracts and scores identical.

**Non-Goals:**

- Changing risk tiers, SoD delta semantics, or attribute key names on the standalone operations.
- Removing result-account persistence (audit still writes; only the combined path skips verify polling).
- Parallelizing Dynamic Approver / Dynamic Approval workflows (they still use risk alone).

## Decisions

### D1: Bounded concurrency helper

- **Choice**: Shared `mapWithConcurrency` (limit 5 by default) plus promise-memoize maps for per-id caches.
- **Reason**: Matches the machine-identity entitlements pattern already in this package; unbounded `Promise.all` risks 429s on large roles.
- **Alternatives**: Unbounded parallel — rejected for throttle risk. Serial with caching only — rejected, still linear in object count.

### D2: Combined command returns summary for workflow branching

- **Choice**: `ctx.respond` includes tier, risk summary, contributing ids, has-violation, SoD summary, and violated policy names. Persist uses `waitForCompletion: false` / `verify: false`.
- **Reason**: Trigger deadlines cannot absorb DelimitedFile provisioning polls; the HTTP body is available immediately.
- **Alternatives**: Keep Get Accounts — rejected, reintroduces index waits. Skip persist entirely — rejected, loses audit trail.

### D3: Shared entitlement expansion cache in the combined path

- **Choice**: Request-scoped memoized expander passed into risk catalog and SoD expansion so a role fetched for risk is not re-expanded for SoD.
- **Reason**: Combined path otherwise doubles the hottest ISC calls.
- **Alternatives**: Only parallelize within each op — still duplicates across ops.

### D4: Preserve driver and policy order

- **Choice**: Fetch in parallel, assemble results in input/API order before summarizing.
- **Reason**: `contributing-ids` and policy-name lists stay deterministic for tests and consumers.

## Risks / Trade-offs

[Risk] Higher concurrent ISC load → Mitigation: default concurrency 5; existing throttle-retry middleware.

[Risk] Workflow import forgets re-wiring → Mitigation: workflow contract tests assert the single invoke and summary paths.

[Trade-off] Combined command owns its own persist identity → Accepted: avoids colliding with standalone accounts.

## Migration Plan

1. Deploy connector with `custom:access-request-precheck`.
2. Re-import Access Request Pre-Check workflow; re-apply Configuration and Get Access Token auth.
3. Leave Dynamic Approver workflows on `custom:evaluate-access-request-risk`.

Acceptance: unit tests for concurrency/dedupe/delta semantics; workflow specs; `npm test`, `npm run typecheck`, `npm run build`.
