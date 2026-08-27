## Why

Access-model SoD scan idempotency today searches for ASSIGNED form instances before launching remediation forms. That misses concurrent and retry scenarios where child result-source accounts already exist but forms have moved to SUBMITTED or COMPLETED, and it adds a tenant-wide form search per scan. Operators re-invoking a partial scan (e.g., 2/3 forms in flight, 1 submitted) need safe skip behavior aligned with persisted workflow outputs, not live form state alone.

## What Changes

**Scan idempotency signal**
- From: Skip when an ASSIGNED form instance exists with matching `formInput.parentRequestId`, `accessItemId`, and `policyId` (one `searchFormInstancesByTenantV1` per scan).
- To: Skip when a child result-source account already exists at `{requestId}:{accessItemId}:{policyId}` via `findAccountOnSource`; no form instance search.
- Reason: Child persist is the workflow contract; existing accounts must not be overwritten on retry.
- Impact: Non-breaking for output schema; behavior change for retries and concurrency.

**Skip scope on match**
- From: Skip form creation only.
- To: Skip form creation and child persist (no putAccount overwrite).
- Reason: Preserve first-writer child outputs.
- Impact: Non-breaking.

**forms-skipped counter semantics**
- From: Count of ASSIGNED duplicate forms skipped within the same parent `requestId`.
- To: Count of violations skipped because the child persist account already exists.
- Reason: Align rollup with new idempotency signal.
- Impact: Non-breaking field name; meaning change for operators reading logs.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `connector-operations/access-model-sod-remediation`: Replace request-scoped pending form dedupe requirement with child persist account idempotency; update form launch idempotent scenario.
- `ubiquitous-language`: Replace **request-scoped form dedupe** with **child persist account idempotency**; update **forms-skipped** and **parent request id** notes.

## Impact

- **Code:** `src/operations/access-model-sod-remediation/index.ts`, `form-service.ts` (remove form-instance dedupe helpers), tests, README.
- **Specs:** Main spec deltas for access-model-sod-remediation and ubiquitous-language.
- **Workflows:** Retries of the same `requestId` skip violations that already have child accounts; no duplicate forms or account overwrites.
- **ISC API:** Removes per-scan `searchFormInstancesByTenantV1` from dedupe path; adds per-violation account lookup (same pattern as apply idempotency).
