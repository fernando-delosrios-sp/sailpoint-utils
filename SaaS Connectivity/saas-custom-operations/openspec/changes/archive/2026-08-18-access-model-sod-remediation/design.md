## Context

`custom:access-model-sod-remediation` scans enabled roles/access profiles, creates remediation forms for intrinsic SoD violations, and today persists rollup counters on `requestId` plus per-form output on child identities. The user wants rollup metrics on the invoke response only and child accounts as the sole persisted result-source rows.

## Goals / Non-Goals

**Goals:**
- Remove `ctx.persist(ctx.requestId, rollup)` from the handler
- Return rollup fields on successful `ctx.res.send`
- Keep child persist at `{requestId}:{accessItemId}:{policyId}` unchanged
- Update specs, tests, and README for workflow migration

**Non-Goals:**
- Changing child output fields or form behavior
- Framework-wide invoke dedupe replay of summary payloads
- Schema removal of rollup-typed output keys (they remain typed for response documentation)

## Decisions

### D1: res.send payload uses existing prefixed keys

- **Choice:** `{ status: 'success', 'access-model-sod-remediation:access-items-scanned': n, 'access-model-sod-remediation:violations-found': n, ...optional counters }`
- **Reason:** Workflows already know attribute names; only the read location changes (invoke step vs Get Accounts)
- **Considered alternatives:** Nested `summary: { ... }` object — rejected (extra JSONPath churn)

### D2: No persist on requestId for success path

- **Choice:** Delete parent rollup persist block entirely
- **Reason:** User explicitly requested no summary account
- **Considered alternatives:** Empty parent account with only core attributes — rejected (still surfaces summary row in aggregation)

### D3: Optional counters remain optional in res.send

- **Choice:** Include `forms-skipped` / `forms-persist-failed` only when > 0 (same as current parent persist spread)
- **Reason:** Preserve existing semantics and payload size behavior

### D4: OperationSignature.output typing unchanged

- **Choice:** Keep rollup keys on `AccessModelSodRemediationOperation.output`; handler sends them via `res.send`, child keys still persist on children only
- **Reason:** Codegen/schema sidecar continues to document all operation outputs; framework does not auto-persist from output typing

## Risks / Trade-offs

- [Risk] Workflows still reading parent account miss rollup after upgrade → Mitigation: README + CHANGELOG breaking note; delta spec migration text
- [Risk] Duplicate invoke dedupe returns bare `{ status: 'success' }` without summary → Mitigation: Document as existing framework limitation; out of scope
- [Trade-off] Invoke response carries more fields than before → Accepted: required for summary delivery

## Migration Plan

1. Deploy connector with handler change
2. Update orchestrating workflow: bind rollup fields to Custom Command step response instead of subsequent Get Accounts on `requestId`
3. Remove or skip workflow steps that list/read parent account for rollup only
4. Child notification loop (Get Accounts on `{requestId}:{accessItemId}:{policyId}`) unchanged
5. Rollback: revert handler to restore parent persist + minimal res.send

## Open Questions

None.
