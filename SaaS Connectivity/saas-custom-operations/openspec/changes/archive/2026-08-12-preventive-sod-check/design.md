## Context

Access approval workflows need a preventive signal: would an identity violate SoD if pending grant access requests complete? A standalone prototype (`.scratch/sod-check`, not in repo) validated the predict-based approach using ISC `startPredictSodViolationsV1`. An alternate ABB implementation (`check-sod-pending`) used local policy matching — rejected as weaker and harder to maintain.

The connector already ships `custom:sod-remediation` with namespaced persist outputs (`sod-remediation:situation-summary`, etc.). This change adds a sibling operation that evaluates **executing** GRANT_ACCESS requests for an identity, predicts violations, and persists workflow-friendly summary fields under the `preventive-sod-check:` namespace.

ISC integration follows existing patterns: thin wrappers under `src/isc/<api-grouping>/`, SDK loopback via `ctx.sdk`, offline fixtures for local invoke, and operation logic under `src/operations/preventive-sod-check/`.

## Goals / Non-Goals

**Goals:**
- Register `custom:preventive-sod-check` with input `identityId` (required) and optional `accessRequestId`
- Discover executing GRANT_ACCESS requests, resolve granted items via events index search with retry, expand roles/APs to entitlements, call SoD predict API
- Persist `preventive-sod-check:situation-summary` and `preventive-sod-check:violated-policy-names` (string[] of all violated policies)
- Build situation summary text per agreed rules; optional `accessRequestId` affects narrative only

**Non-Goals:**
- `approved` boolean/string output (dropped from scratch prototype)
- Local SoD policy ID matching
- `access-request-status`, `access-request-threshold`, or remediation/revoke actions
- Substitute for ISC violation certification or violation management workflows

## Decisions

### D1: Evaluation engine — ISC predict API
- **选择:** `SODViolationsApi.startPredictSodViolationsV1` with `IdentityWithNewAccess` (identityId + entitlement accessRefs).
- **理由:** ISC-native prediction matches tenant SoD policies; same engine used by `.scratch/sod-check`.
- **已考虑 alternative:** Local policy matcher (ABB `check-sod-pending`) — rejected; diverges from tenant policy state and misses predict API refinements.

### D2: Pending grant discovery — access request status + GRANT_ACCESS filter
- **选择:** `AccessRequestsApi.listAccessRequestStatusV1` with `requestedFor = identityId`, `requestState = EXECUTING`; keep only items where `operation === 'GRANT_ACCESS'`.
- **理由:** EXECUTING state captures approved-but-not-yet-provisioned grants; GRANT_ACCESS excludes revokes and non-grant operations.
- **已考虑 alternative:** Query all pending approvals regardless of state — too broad; includes not-yet-approved requests.

### D3: Item resolution — events index search with retry
- **选择:** For each executing request's `trackingNumber`, search the `events` index via `SearchApi.searchPostV1` with a query on tracking number; retry with bounded backoff when events are not yet indexed (provisioning lag).
- **理由:** Access request status lists requests but not always resolved entitlement/role/AP ids; events index is the authoritative provisioning trail per scratch algorithm.
- **已考虑 alternative:** Use status payload item ids only — insufficient when provisioning events lag behind status.

### D4: Entitlement expansion — reuse existing isc modules
- **选择:** Resolve event access items to entitlement ids: pass through ENTITLEMENT items; expand ROLE via `src/isc/roles/` and ACCESS_PROFILE via `src/isc/access-profiles/`; dedupe entitlement ids before predict call.
- **理由:** Predict API accepts entitlement refs; roles/APs must flatten to entitlements.
- **已考虑 alternative:** Pass role/AP refs to predict — API contract expects entitlement refs in `accessRefs`.

### D5: Namespaced persist outputs (aligned with sod-remediation)
- **选择:** Persist only `preventive-sod-check:situation-summary` (plain text) and `preventive-sod-check:violated-policy-names` (string[]).
- **理由:** Workflows branch on summary text and policy list; namespace avoids collision with other operations on shared result sources.
- **已考虑 alternative:** Include `approved` flag from scratch — user explicitly dropped it.

### D6: Situation summary builder rules
- **选择:** Pure function `buildPreventiveSituationSummary({ violatedPolicyNames, accessRequestId? })`:
  - Zero violations → `"No violations found"`
  - Violations, no `accessRequestId` → list all violating policy names (plain text, comma-separated or bullet-style sentence)
  - Violations, with `accessRequestId` → attribute summary to that access request (e.g. reference request id and name policies that would be violated if it completes)
  - `violated-policy-names` output always contains the **full** set from predict response regardless of `accessRequestId`
- **理由:** Optional `accessRequestId` is workflow context for attribution; policy list remains complete for branching/notification.
- **已考虑 alternative:** Filter policy list to request-attributed subset when `accessRequestId` present — rejected; user requires full set always.

### D7: SDK client extensions
- **选择:** Extend `ctx.sdk` with `accessRequests: AccessRequestsApi`, `search: SearchApi`, `sodViolations: SODViolationsApi`; wrap public helpers in `src/isc/access-requests/`, `src/isc/events-search/`, `src/isc/sod-prediction/`.
- **理由:** Matches per-API subdirectory layout in target-client spec; keeps operation handler thin.
- **已考虑 alternative:** Inline SDK calls in operation — rejected; breaks isc module boundary conventions.

### D8: Operation module layout
- **选择:** `src/operations/preventive-sod-check/` with `index.ts` (handler), `situation-summary.ts` (builder), `pending-grants.ts` (orchestration), `offline-data.ts`, `README.md`.
- **理由:** Consistent with sod-remediation folder structure and auto-registration codegen.

### D9: Error handling
- **选择:** Fail with `ConnectorError` on required API failures (access request list, predict API). Treat empty executing grants as success with `"No violations found"` and empty policy array. After retry exhaustion with no events for a tracking number, skip that request with logged warning (do not fail entire operation unless zero items resolved across all requests).
- **理由:** Partial provisioning lag should not block check when other requests yield entitlements; total failure only when predict cannot run meaningfully.
- **已考虑 alternative:** Fail if any tracking number lacks events — too brittle during provisioning windows.

### D10: Authentication
- **选择:** Standard invocation envelope (`apiUrl`, `token`); PAT scopes must include access request read, search/events read, and SoD predict. Offline mode uses canned fixtures without live API calls.
- **理由:** Same loopback pattern as other custom operations.

## Risks / Trade-offs

- [Risk] Events index lag exceeds retry window → Mitigation: configurable max attempts/delay; log skipped requests; document expected workflow timing
- [Risk] Predict API response shape changes → Mitigation: isolate parsing in `src/isc/sod-prediction/`; fixture tests with recorded payloads
- [Risk] Large number of executing grants → Mitigation: paginate access request status; batch predict single call with deduped entitlements
- [Trade-off] Plain-text summary vs HTML email body → Accept: sod-remediation uses HTML for remediation forms; preventive check is branching-oriented plain text per user contract
- [Trade-off] No per-request violation attribution in policy list → Accept: summary text carries attribution when `accessRequestId` provided; full policy list for workflow logic

## Migration Plan

N/A — new custom command; no breaking changes to existing operations.

Deploy steps:
1. Merge implementation; run codegen to register `custom:preventive-sod-check` in `connector-spec.json` and `auto-registry.ts`
2. Publish updated connector bundle to tenant
3. Wire ISC workflows to invoke with `identityId` and optional `accessRequestId`; read persisted `preventive-sod-check:*` fields from result source

Rollback: remove workflow step invoking the command; prior connector bundle remains compatible (command simply absent).

## Open Questions

- Exact events index query field for tracking number (confirm at implementation spike against tenant search schema)
- Default retry count and delay for events search (propose 3–5 attempts, 1–2s backoff; tune from scratch constants if recovered)
- Whether executing requests with zero resolved entitlements after retry should produce `"No violations found"` or a distinct summary — default: treat as no additional access to predict
