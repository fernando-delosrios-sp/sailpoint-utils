# Proposal: SOD remediation revocable-only access search

## Why

Downstream workflows use `groupAAccessSearch` / `groupBAccessSearch` to fetch access items for corrective removal after the owner selects a remediation side. Those filters currently include every resolved path id, including entitlements marked not directly revocable when a role or access profile grants them on the same side. Workflows cannot act on those entitlements; including them causes failed or misleading revoke steps.

## What Changes

**Access search string composition**
- From: Join all resolved access path item ids with ` OR `
- To: Join only items where `revocable === true`
- Reason: Search strings represent workflow-actionable access to revoke, aligned with revocability annotation
- Impact: **Behavior change** for workflows that depended on non-revocable entitlement ids in the filter; form keys and owner-facing HTML unchanged

**Implementation**
- Add `buildRevocableAccessSearchString()` filtering revocable paths before building the filter
- Wire through `assembleFormInput()` for both sides
- Update tests and documentation

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `connector-operations/sod-remediation`: Tighten hidden access search string requirements to revocable-only path items; add scenario for mixed revocable/non-revocable side

## Impact

- **Code:** `access-path-resolver.ts`, `context.ts`, related unit tests
- **Docs:** README workflow note, CHANGELOG patch entry
- **Tenants:** No seed key changes; values on next launch differ when side has non-revocable entitlements
- **Non-breaking:** Form keys, persist outputs, and HTML display contract unchanged
