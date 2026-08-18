# Brainstorm: access-sod-remediation

## Background

Governance teams need proactive **catalog hygiene**: roles and access profiles should not bundle entitlements that violate enforced SoD policies by design. `custom:sod-remediation` remediates **existing identity violations** (violation ID → form for violation owner). This operation inverts the subject — scan **access catalog items** (roles/APs), detect intrinsic policy conflicts, and route remediation forms to **policy owners**.

Grilling session established scope via `/grill-with-docs` (2026-08-13).

## Decision chain

**Q1: Evaluation model?**
Intra-artifact self-conflict — a role/AP's bundled entitlements contain items from both Group A and Group B of a policy. Not assignment-risk on identities. **No SoD predict API.**

**Q2: Scope parameter?**
`scope` defaults to `"*"` (search wildcard → all items). Optional `searchIndices` default `['accessprofiles', 'roles']`; only those two values valid. Paginated SDK list; enabled items only; when scope is not `*`, append as filter.

**Q3: Form granularity?**
One standalone form instance per **(access item, policy)** pair. Access item = role or access profile.

**Q4: Form recipient?**
Policy owner from **Policies API** (`ownerRef` on SoD policy definition). New `src/isc/sod-policies/` client module.

**Q5: Form UX / remediation outcome?**
No action selector (Correct-only flow). User picks side to remove (`remediationSide`: `groupA` | `groupB`). Downstream workflow removes entitlements from role/AP definition. No Mitigate / compensating controls. Launch inputs: access item id/type/name, policy id/name, group entitlement id lists. Submit: `remediationSide` + optional `comments`.

**Q6: Nested AP display vs evaluation?**
Role/AP under review is **form context**, not a group line item. Expand direct entitlements + nested AP entitlements for violation check. Group HTML may group entitlements under nested AP labels for clarity. **Group id lists are entitlement ids only** (Q8). Trim is entitlement-level on parent role/AP.

**Q7: Evaluation engine (revised)?**
Do **not** use predict. Break role/AP into entitlements. Parse each policy's `policyQuery` (e.g. `@access(id:A OR id:B) AND @access(id:C OR id:D)` — top-level AND separates sides; OR within side). Fallback to `conflictingAccessCriteria` when query missing/unparseable. Violated when item entitlements intersect both sides.

**Q8: Group id lists?**
Entitlement ids only — intersection of item entitlements with each policy side.

**Q9: Form contract?**
Confirmed: `formInput` carries access item + policy + `groupAIds`/`groupBIds` + HTML; `formData` carries `remediationSide`. No access-search strings.

**Q10: Operation output (revised)?**
Drop `forms-created` and indexed suffix keys. **Parent** `{requestId}`: scan rollup (`access-items-scanned`, `violations-found`, optional `forms-skipped`). **Child** per form: `` `${requestId}:${accessItemId}:${policyId}` `` with full per-form output (`form-url`, access item fields, policy fields, `recipient-id`). Cap 100 forms per run (log warning).

**Q11: Re-run idempotency?**
Skip when ASSIGNED standalone instance exists for same `(formDefinition, accessItemId, policyId)`.

**Q12: Role + nested AP both in scope?**
Evaluate independently; note parent role in AP standalone form when relevant.

**Q13: Policy side resolution?**
`policyQuery` first; `conflictingAccessCriteria` fallback.

**Q14: Which policies?**
Configurable `policyScope` default `state eq "ENFORCED"`. Evaluate all matching policies per run (v1).

**Q15: Nested AP display vs ids?**
HTML groups by nested AP; workflow ids remain entitlement-level.

## Out of scope (v1)

- SoD predict / identity assignment risk
- Mitigate / compensating controls
- Removing nested AP as single unit from role
- Per-form email persist on parent account
- Entitlement-index optimization for policy scanning
