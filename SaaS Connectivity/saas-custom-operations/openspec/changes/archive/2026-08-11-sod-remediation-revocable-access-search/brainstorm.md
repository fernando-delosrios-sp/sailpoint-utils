# Brainstorm: sod-remediation-revocable-access-search

Raw capture from design exploration (Aug 2026).

## Background

SOD remediation emits per-side ISC access-item search filters (`groupAAccessSearch` / `groupBAccessSearch`) for downstream workflows to fetch access targeted for corrective removal. The original access-search change joined **all** resolved path item ids (entitlements plus expanded access profiles/roles).

Revocability annotation (shipped in `sod-remediation-revocability`) marks entitlements granted via role/AP on the same side as **not directly revocable**. Owner-facing HTML already distinguishes revocable vs informational lines. Workflows consuming the search strings still receive non-revocable entitlement ids — e.g. `id:ent-b OR id:role-1` when only the role is actionable.

## Agreed scope

**In scope:**
- Filter access search strings to **revocable-only** access path items
- Keep owner-facing HTML columns and email summary showing **all** paths (including non-revocable entitlements with grantor context)
- Update spec delta, tests, README note, CHANGELOG patch note

**Out of scope:**
- Changing revocability derivation rules
- Reintroducing hidden JSON revoke payloads
- Workflow revoke execution in the connector
- Seed form element changes (keys unchanged; values change at launch)

## Decision chain

### Q1: Filter at builder vs caller?
**Decision:** Add `buildRevocableAccessSearchString(accessPaths)` in `access-path-resolver.ts` that filters `revocable === true` then delegates to existing `buildAccessSearchString`. Keeps filtering rule co-located with path resolution types.

### Q2: What about sides with mixed revocable and non-revocable items?
**Decision:** Search string includes only revocable ids. Example: entitlement + role on side → `id:role-1` only, not the entitlement.

### Q3: Empty revocable set?
**Decision:** Return empty string `''`. In practice, sides with elevated paths always include at least one revocable role/AP; entitlement-only sides mark entitlements revocable. Document edge case in spec.

### Q4: Display vs workflow contract?
**Decision:** Unchanged split — HTML shows full path context; search strings are workflow-actionable subset only.

### Q5: Breaking change?
**Decision:** Behavior change for workflows that relied on non-revocable ids in search filters. PATCH semver note in CHANGELOG; no new form keys.

## Approaches considered

| Approach | Trade-off |
|----------|-----------|
| Filter in `assembleFormInput` inline | Rejected — scatters revocability rule; harder to test |
| New helper wrapping filter + builder | **Selected** — single test surface, clear name |
| Change `buildAccessSearchString` signature to require revocable flag on items | Rejected — generic builder stays reusable for logging/other callers |

## Acceptance criteria

- `npm test` passes
- `context.spec.ts` expects `groupBAccessSearch` = `id:role-1` (not `id:ent-b OR id:role-1`) for role-granted entitlement fixture
- Delta spec requires revocable-only ids in access search strings
- CHANGELOG notes corrected workflow filter behavior
