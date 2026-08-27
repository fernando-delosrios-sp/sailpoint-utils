## Context

`custom:access-model-sod-remediation` scans catalog access items, detects intrinsic SoD violations, and launches standalone remediation forms. Child workflow outputs persist at `{requestId}:{accessItemId}:{policyId}`. Form-instance dedupe (`hasAssignedRemediationInstance`) currently ignores `requestId`, causing cross-scan suppression. The user requires dedupe scoped to the parent scan's `requestId`.

## Goals / Non-Goals

**Goals**
- Store `parentRequestId` on every new remediation form instance (`formInput`, declared, no UI).
- Dedupe pending (ASSIGNED) instances by `{parentRequestId, accessItemId, policyId}` within the form definition.
- Preserve one `searchFormInstancesByTenantV1` call per scan via existing cache; extend cache keys.
- Cover behavior with unit tests mirroring delta spec scenarios.

**Non-Goals**
- Backfill `parentRequestId` on existing instances.
- Change apply-command idempotency (`formInstanceId`-keyed).
- Add ISC list filters for `formInput` fields (not supported; client-side filter retained).
- C4 diagram (single handler + ISC Forms; no new containers).

## Decisions

### 1. `formInput.parentRequestId` field name and source

**Decision:** Add `parentRequestId` to the seed's declared `formInput` array; set to `ctx.requestId` in `createAccessModelSodRemediationInstance` call path.

**Rationale:** Matches ubiquitous-language "parent request id" and child persist prefix without overloading generic `requestId` on downstream apply invokes.

**Alternatives considered:** Result-source-only dedupe (read child accounts) — rejected because user asked for pending form instances from ISC Forms, and persist may be missing when launch succeeded but persist failed.

### 2. Pending state = ASSIGNED

**Decision:** Unchanged — only `state === 'ASSIGNED'` instances participate in dedupe.

**Rationale:** Consistent with prior idempotency semantics; submitted/completed forms should not block new remediation cycles.

### 3. Cache key shape

**Decision:** Replace `assignedPairs` key `${accessItemId}:${policyId}` with `${parentRequestId}:${accessItemId}:${policyId}`.

**Rationale:** Minimal change to existing scan-scoped cache; `hasAssignedRemediationInstance` gains `parentRequestId` parameter.

### 4. Legacy instances

**Decision:** Instances missing `formInput.parentRequestId` are ignored by dedupe matching.

**Rationale:** No migration API; avoids false positives. Operators may see duplicate pending forms only when old unscoped instances coexist with new scans — acceptable trade-off documented in README.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Duplicate pending forms across scans for same violation | Intended behavior; child persist keys differ by `requestId` |
| Seed fingerprint change | Document new `formName` adoption pattern (existing project convention) |
| Search limit 250 instances | Unchanged risk; same as today |
| Stale legacy ASSIGNED forms visible in tenant | Manual cleanup; no longer block new scans |

## Migration Plan

1. Deploy connector with updated seed and handler.
2. Adopt new `formName` in workflow input when ready for `parentRequestId` on new instances (optional if definition recreated).
3. Complete or cancel legacy ASSIGNED instances if operators want a clean tenant view.
4. No data migration script.

## Open Questions

None.
