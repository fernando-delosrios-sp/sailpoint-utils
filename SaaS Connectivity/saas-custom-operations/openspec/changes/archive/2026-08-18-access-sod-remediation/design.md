## Context

Governance teams need to detect when roles or access profiles **intrinsically violate** enforced SoD policies — before those items are assigned to identities. The connector already ships `custom:sod-remediation` (identity violation → violation-owner form) and `custom:preventive-sod-check` (predict API for pending grants). This change adds a **catalog scan** operation that evaluates access item entitlement contents against policy definitions and launches policy-owner remediation forms.

Grilling session (2026-08-13) rejected SoD predict for this use case. Evaluation uses **policy query parsing**: expand role/AP to entitlements, parse each policy's `policyQuery` (AND between sides, OR within side), detect intersection on both sides, and create forms patterned on sod-remediation's Correct flow.

Persist follows the `custom:example` child-identity pattern: parent rollup on `requestId`, per-form detail on `` `${requestId}:${accessItemId}:${policyId}` ``.

## Goals / Non-Goals

**Goals:**
- Register `custom:access-sod-remediation` with scoped role/AP discovery and policy evaluation
- Parse `policyQuery` with `conflictingAccessCriteria` fallback
- Create one standalone form per (access item, policy) for policy owner; skip duplicates when ASSIGNED instance exists
- Parent/child persist: rollup on parent; per-form fields on deterministic child identities
- Reuse forms ensure-from-seed, entitlement expansion from existing roles/access-profiles modules

**Non-Goals:**
- SoD predict API or identity assignment-risk analysis
- Mitigate / compensating controls on forms
- Nested AP removal as a unit (entitlement-level trim only)
- Per-form email fields on parent persist
- Entitlement-index policy filtering optimization (v1 scans all policies matching `policyScope`)

## Decisions

### D1: Evaluation — policy query intersection (not predict)
- **选择:** Expand access item to flat entitlement ids; for each policy resolve Group A and Group B entitlement sets from `policyQuery`; violated when `(itemEntitlements ∩ groupA) ≠ ∅` AND `(itemEntitlements ∩ groupB) ≠ ∅`.
- **理由:** Catalog hygiene is definitional — policy query expresses side membership directly; predict requires identity context and evaluates assignment risk.
- **已考虑 alternative:** `startPredictSodViolationsV1` with baseline identity — rejected at grilling.

### D2: Policy side resolution — query first, structured fallback
- **选择:** Parse `policyQuery` string (`@access(id:… OR id:…) AND @access(id:… OR id:…)`); on missing/unparseable query use `conflictingAccessCriteria.leftCriteria/rightCriteria` entitlement lists; skip policy when neither yields two non-empty sides.
- **理由:** API returns both shapes; query is authoritative when present; structured data covers edge cases.

### D3: Access item discovery — paginated SDK list with scope filter
- **选择:** `searchIndices` controls which catalogs to scan (default both `accessprofiles` and `roles`); paginate enabled items via RolesApi / AccessProfilesApi; `scope: "*"` means no extra filter; otherwise append scope as ISC filter string.
- **理由:** Matches user contract; reuses SDK pagination patterns from other modules.

### D4: Role expansion includes nested AP entitlements
- **选择:** When evaluating a role, union direct role entitlements with entitlements from nested access profiles on the role definition. Standalone AP evaluation uses AP entitlements only.
- **理由:** Toxic combination may arise from nested AP contents bundled into a role.

### D5: Form context vs group display
- **选择:** Access item under review (role or AP name/id) is form **context** — not listed in Group A/B columns. Group HTML lists entitlements; may visually group under nested AP labels. `groupAIds` / `groupBIds` on `formInput` are **entitlement ids only** (intersection with policy sides).
- **理由:** User clarified role/AP is the subject; remediation trims entitlements on the parent definition.

### D6: Form UX — Correct-only side selection
- **选择:** Single required `remediationSide` select (`groupA` | `groupB`); no action selector, no Mitigate section, optional `comments`. Downstream workflow removes entitlements on chosen side from role/AP definition.
- **理由:** No identity violation record exists; compensating controls do not apply to catalog design.

### D7: Form recipient — policy owner from Policies API
- **选择:** Resolve recipient from policy `ownerRef` via new `src/isc/sod-policies/` get helper. Form instance recipient type IDENTITY.
- **理由:** User chose policy owner (Q4-A); distinct from sod-remediation violation owner.

### D8: Form granularity and idempotency
- **选择:** One form per (access item, policy). Before create, search for ASSIGNED standalone instance with same form definition name and matching `formInput.accessItemId` + `formInput.policyId`; skip if found.
- **理由:** Targeted remediation; avoid duplicate open forms on scheduled re-runs.

### D9: Parent/child persist model
- **选择:** Parent `ctx.persist(requestId, rollup)` with scan counters. Each form `ctx.persist(\`${requestId}:${accessItemId}:${policyId}\`, perFormOutput)`. No `forms-created` counter on persist (count derivable from child accounts or logs).
- **理由:** User revision — child requestId per form replaces indexed suffix keys; aligns with `custom:example` pattern.

### D10: Cap and overlap handling
- **选择:** Max 100 forms created per invocation; log warning and stop creating beyond cap. Role and nested AP in scope evaluated **independently**.
- **理由:** Prevent persist/schema blow-up; accept duplicate policy hits across role vs standalone AP in v1.

### D11: Module layout
- **选择:** Operation under `src/operations/access-sod-remediation/`; policy logic in `src/isc/sod-policies/`; list helpers extend `src/isc/roles/` and `src/isc/access-profiles/`; form seed + form-service co-located with operation (sod-remediation pattern).
- **理由:** Consistent with operation-layer-boundaries and target-client per-API folder conventions.

### D12: Authentication
- **选择:** Standard invocation envelope; PAT scopes for Sod Policies read, Roles/Access Profiles read, Custom Forms create, Public Identities read (owner email if needed later). Offline mode uses canned policies, items, and form stubs.
- **理由:** Same loopback pattern as sibling operations.

## Risks / Trade-offs

- [Risk] `policyQuery` format variations beyond documented AND/OR pattern → Mitigation: structured fallback; unit tests with recorded tenant samples; log skip reason
- [Risk] Large tenant catalog × many policies → Mitigation: 100-form cap; document batch scheduling; future entitlement-index optimization
- [Risk] Policy owner is workgroup not identity → Mitigation: v1 require IDENTITY ownerRef; fail/skip with logged warning when unsupported
- [Trade-off] Independent role + AP evaluation may duplicate forms for same entitlements → Accept for v1
- [Trade-off] Entitlement-level trim only → Accept; nested AP unit removal deferred

## Migration Plan

N/A — new custom command; no breaking changes to existing operations.

Deploy steps:
1. Merge implementation; run codegen to register `custom:access-sod-remediation`
2. Publish connector bundle; create shared form definition via first invoke with `formName`
3. Wire workflow: invoke scan → read parent rollup → iterate child accounts by known `(accessItemId, policyId)` pairs or account search

Rollback: remove workflow invoke step; prior bundle remains compatible.

## Open Questions

- Exact Sod Policies list API filter syntax for `policyScope` (confirm at implementation spike)
- Whether policy `ownerRef` type GOVERNANCE_GROUP should be supported in v1 or explicitly rejected
- Default form instance expiry (propose 30 days, match sod-remediation)
