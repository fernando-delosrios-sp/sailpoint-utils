# Proposal: Ignore access profile grantors on identity SoD remediation

## Why

Corrective revoke today targets assigned access profiles when they grant a conflicting entitlement. Requested entitlements often remain or return after the profile is removed, so the violation is not cleared. Roles still re-grant entitlements if left assigned, so they stay as parent access items. Treating entitlements independently of access profiles makes the workflow revoke the entitlement ids themselves.

## What Changes

**Identity SoD access path parents**
- From: Any assigned access profile or role that grants a conflicting entitlement is a parent access item (elevated path); entitlements on that side are not directly revocable
- To: Only assigned **roles** are parent access items. Access profiles are not on the path. Entitlements not granted via a role are revocable and appear in the access search string
- Reason: Profile-level revoke does not clear requested entitlements; role-level revoke still must remove the grantor
- Impact: **Behavior change** for `groupAAccessSearch` / `groupBAccessSearch` and owner-facing HTML on next form launch; persist keys unchanged

**Identity access listing**
- From: `fetchIdentityAccessItemsFromSdk` lists access profiles and roles with granted entitlement ids
- To: List roles only (offline canned data aligned)
- Reason: Only `custom:sod-remediation` consumes this helper; AP listing is unused and would reintroduce AP path lines
- Impact: Helper contract change; no other operations call it

**Form / warning copy**
- From: Display AP lines with Contains grouping; elevated warning mentions profile- or role-level access
- To: No AP path lines on identity SoD; elevated warning is role-level only
- Reason: Owners must not be told an AP is being removed when it is not a revoke target
- Impact: Visual change on new form instances only

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `connector-operations/sod-remediation`: Path resolution, revocability, search strings, and warnings treat roles as the only parent access items
- `target-client/identity-access`: SDK and offline listing return roles only, not access profiles
- `ubiquitous-language`: Add **parent access item**; note identity SoD no longer uses AP grantors

## Impact

- **Code:** `src/operations/sod-remediation/access-path-resolver.ts` and tests; warning copy; README workflow notes; `src/isc/identity-access/` fetch + offline data + tests
- **Docs:** CHANGELOG; operation README (search semantics, AP not a revoke target)
- **Workflows:** Bundled remediation JSON unchanged; Get Access already includes entitlements. Existing form instances keep launch-time search strings until a new launch
- **Out of scope:** `custom:access-model-sod-remediation` / apply; connector-spec command list; persist output schema; extra AP revoke or catalog PATCH
