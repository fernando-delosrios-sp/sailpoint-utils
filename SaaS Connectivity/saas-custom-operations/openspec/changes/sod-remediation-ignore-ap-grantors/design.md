## Context

`custom:sod-remediation` is launch-only. It resolves identity access paths, marks revocability, and writes `groupAAccessSearch` / `groupBAccessSearch` for the bundled **SOD Violation - Remediation** workflow (`Get Access` → `Manage Access` `REVOKE_ACCESS`). Today `resolveAccessSide` treats assigned access profiles and roles as parent access items: entitlements on that side are `revocable: false` (`granted-via-access-profile` or `granted-via-role`), and the search string contains the AP/role id. Revoking the AP does not clear entitlements that were independently requested. Authentication, persist, and operation output mapping stay as they are (loopback token, namespaced form-url / email fields).

## Goals / Non-Goals

**Goals:**

- Ignore access profiles as parent access items on identity SoD paths
- Keep roles as parent access items (entitlements granted via role stay not directly revocable)
- Put standalone (non-role-granted) entitlement ids into the revocable access search string
- Stop listing access profiles in `identity-access` SDK and offline helpers
- Update owner-facing HTML and elevated warning so they do not claim AP removal

**Non-Goals:**

- Detecting requested vs AP-only entitlement assignment via extra ISC calls
- Revoking the AP in addition to entitlements, or PATCHing AP definitions
- Changing bundled workflow step graph or persist/output keys
- Changing access-model SoD operations or sod-form-html APIs (library may still nest AP grantors if given AP lines)

## Decisions

### D1: Resolver ignores ACCESS_PROFILE identity items

- **Choice**: `resolveAccessSide` only considers `ROLE` items from identity access when attaching grantors. Entitlements without a role grantor are `revocable: true` with `reason: direct-assignment` even if an AP on the identity also contains them
- **Reason**: Single place that already owns path/revocability; search strings stay `buildRevocableAccessSearchString`
- **Considered alternatives**: Keep AP on the path but revoke entitlements instead (display/search split) — rejected; owners would see AP removed while AP is not revoked. Revoke AP **and** entitlements — rejected; discovery chose ignore APs

### D2: Roles remain the only elevated grantor

- **Choice**: `hasElevatedPath` / `granted-via-role` / recommended revoke priority unchanged for roles. `granted-via-access-profile` is not produced for identity SoD paths
- **Reason**: A remaining role re-grants the entitlement; same failure mode the AP path had, still valid for roles
- **Considered alternatives**: Also ignore roles — rejected in discovery

### D3: Stop fetching access profiles in identity-access

- **Choice**: `fetchIdentityAccessItemsFromSdk` lists roles only (no `accessProfile` identity-history call, no AP entitlement expansion). Offline map uses a role (or empty), not an AP
- **Reason**: This helper is only used by sod-remediation; listing APs would be wasted loopback and could leak AP lines if the resolver missed a filter
- **Considered alternatives**: Keep fetching APs and filter in the resolver only — rejected as footgun plus extra API calls

### D4: No workflow or output-schema change

- **Choice**: Leave `workflows/SOD Violation - Remediation.json` structure as-is. Get Access already sets `entitlements: true`. No connector-spec or OperationSignature output change
- **Reason**: Search string value change is sufficient
- **Considered alternatives**: New formInput keys for entitlement vs role lists — rejected as unnecessary for Manage Access

### D5: Warning and HTML follow the path

- **Choice**: Elevated warning copy is role-level only. Group columns and situation summary omit AP path lines because they are not in `accessPaths`
- **Reason**: Honest owner UX
- **Considered alternatives**: Keep showing APs as removed while revoking entitlements — rejected in discovery Q3

## Risks / Trade-offs

- [Risk] Assigned AP still grants the entitlement after identity refresh, so E returns even after entitlement revoke → Mitigation: accepted residual (discovery Q7); document in README; not a connector retry loop
- [Risk] Existing in-flight form instances still have AP ids in `formInput` search strings → Mitigation: next `custom:sod-remediation` launch writes new values; already-submitted instances are one-shot
- [Trade-off] Identity SoD no longer shows which AP contained the entitlement → Reason for acceptance: AP is not a revoke target; role nesting still explains role-granted entitlements
- [Trade-off] `granted-via-access-profile` reason may remain on types for HTML tests that pass AP lines into the shared library → Reason for acceptance: library is shared; identity SoD simply never emits that reason

## Migration Plan

Deploy connector. Re-invoke `custom:sod-remediation` so new form instances get entitlement/role search strings (form definition fingerprint unchanged unless copy in seed HTML is untouched — seed conditions need not change). No persist schema or connector-spec migration. Rollback: previous connector build restores AP grantors and AP listing. Acceptance: resolver tests for AP-ignored / role-kept / mixed sides; identity-access tests no longer expect AP items; `npm run typecheck` and `npm test` pass.

## Open Questions

None.
