# Proposal: SOD remediation keep recommendations

## Why

After revocability shipped, violation owners still lack ISC’s certification/IAI **keep** guidance. The connector ⭐ “Recommended” badge confused owners because it meant “recommended revoke target,” not “recommended to keep.” Owners need ISC-backed keep stars, clearer non-revocable copy with named grantors, optional privileged indicators, and a side-level hint when keep recommendations favor correcting one group over the other.

## What Changes

**Keep recommendation star**
- From: ⭐ on connector `recommendedRevoke` items in form/email HTML
- To: ⭐ only when Recommendations API returns `YES`, labeled “Recommended to keep”
- Reason: Align UI with ISC IAI/certification semantics
- Impact: Non-breaking for operation I/O; changes visible HTML only

**Non-revocable copy**
- From: “Not revocable (granted via role)”
- To: “Not directly revocable (granted via {Role Name} role)” with named grantor from path expansion
- Reason: Owners need to know which container grants the entitlement
- Impact: Non-breaking

**Side correction hint**
- From: No side-level guidance
- To: When keep recommendations exist on exactly one group, recommend correcting the other group in form columns and `situationSummary`
- Reason: Speed owner decision when ISC signals asymmetric keep intent
- Impact: Non-breaking; new HTML blocks only

**Privileged badge**
- From: No privileged indicator
- To: 🔐 on privileged entitlements when metadata is available
- Reason: Highlight sensitive access in remediation context
- Impact: Non-breaking; requires entitlement listing API at launch

**Hidden payload**
- From: `recommended` boolean on items (UI-facing revoke star)
- To: Per-item `keepRecommendation`; optional `recommendedSideToCorrect`; retain `recommendedRevoke` for workflow without UI star
- Impact: Non-breaking for workflow JSONPath consumers that ignore new keys

## Capabilities

### Modified Capabilities

- `connector-operations/sod-remediation` — keep recommendations, side correction, copy/privileged display, payload extensions

### New Capabilities

- `isc/recommendations` — batch fetch keep recommendations for identity + access item refs

## Impact

- **Dependencies:** New isc client module; optional entitlement history fetch for privileged flag
- **Operational:** No seed structure change expected; if formInput keys added for side hint, admins recreate form definition once (same constraint as prior change)
- **Failure mode:** Recommendations API errors degrade to no keep stars / no side hint (no user-visible error)
