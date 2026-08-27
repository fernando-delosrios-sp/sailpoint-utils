## Why

Access-model SoD remediation forms currently nest offending entitlements under access profile labels in group columns. Policy owners interpret that as trimming entitlements inside the profile, but the intended remediation for role violations is to detach the whole access profile from the role. That mismatch causes wrong expectations before a planned `custom:access-model-sod-correct` operation ships. Flattening AP rows—with an explicit offending-entitlement mention—aligns the form with detach-AP semantics and must land first so owners approve the correct catalog change.

## What Changes

**Group column HTML for nested access profiles**
- From: Nested bullet tree (AP row with child entitlement `<ul>`)
- To: Single flat line per AP: profile name, access profile type tag, and `— offending: <name(s)>` for side-matching entitlements
- Reason: AP is the removable unit on roles; presentation must match planned correct behavior
- Impact: Non-breaking for workflows; new form instances get updated HTML at launch. Existing ASSIGNED instances unchanged until recreated.

**Direct role entitlements on a policy side**
- From: Single flat entitlement line (unchanged)
- To: Same
- Reason: Direct entitlements remain individually removable from the role
- Impact: None

**formInput contract**
- From: `groupAIds` / `groupBIds` are JSON-stringified entitlement id arrays
- To: Unchanged
- Reason: Detection and future correct operation still key off entitlement ids
- Impact: None

**Explicit non-goals**
- `custom:access-model-sod-correct` (separate change)
- Patching access profile definitions or role composition via API
- Form seed JSON or new `formName` watermark
- `custom:sod-remediation` identity violation form HTML

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `connector-operations/access-model-sod-remediation`: Replace nested AP tree group-column requirement with flat AP line + offending entitlement mention; clarify outcome panels apply to whole AP rows
- `sod-form-html`: Add normative requirements for `renderEntitlementTree` flat AP line shape and multi-entitlement offending mention
- `ubiquitous-language`: Promote **flat access profile line** and **offending entitlement mention**; update group-column / type-tag notes where nested AP tree is referenced

## Impact

- `src/lib/sod-form-html/entitlement-tree.ts` — flat AP line rendering
- `src/lib/sod-form-html/sod-form-html.spec.ts` — updated assertions
- `src/operations/access-model-sod-remediation/group-html.spec.ts` — integration expectations
- Delta specs under this change’s `specs/` directory
- CHANGELOG entry during apply
- No `connector-spec.json` command changes
