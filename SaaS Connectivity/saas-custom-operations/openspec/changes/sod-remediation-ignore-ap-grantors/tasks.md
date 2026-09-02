## 1. Identity-access listing (roles only)

- [x] 1.1 Fail `src/isc/identity-access/identity-access.spec.ts` for SDK: list `type: role` only, no `accessProfile` identity-history call, no access-profiles client usage; offline canned items are not `ACCESS_PROFILE`
- [x] 1.2 Update `fetch-identity-access-items.ts` (and `IdentityAccessSdk` if `accessProfiles` is unused) so SDK listing is roles + role entitlement ids only
- [x] 1.3 Update `offline-data.ts` canned identity access to a role (or empty), not an access profile; keep data in `offline-data.ts` separate from fetch orchestration

## 2. Access path resolver

- [x] 2.1 Replace `access-path-resolver.spec.ts` AP-as-grantor cases with: assigned AP ignored (entitlement revocable `direct-assignment`, no AP line, search is entitlement id); role still grantor; role+AP both present → role only; mixed role + standalone entitlement search includes role id and standalone entitlement id only
- [x] 2.2 Change `resolveAccessSide` so only `ROLE` identity items attach as parent access items; `ACCESS_PROFILE` items never enter `accessPaths`; `ELEVATED_WARNING` is role-level only
- [x] 2.3 Keep `buildRevocableAccessSearchString` as the formInput search builder; no new form keys

## 3. Launch HTML and logging

- [x] 3.1 Cover assembleFormInput / situation summary: no access profile path lines or AP Contains grouping when identity access still includes an AP in the test fixture
- [x] 3.2 Update seed static warning copy in `src/operations/sod-remediation/seed/` if it still mentions access-profile-level removal
- [x] 3.3 Drop or zero `accessProfiles` counts in sod-remediation logging if they would always be zero

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 Run `npm run typecheck` and `npm test`
- [x] 4.3 All delta spec scenarios covered by named automated tests (identity-access listing; resolver AP-ignored / role-kept / mixed search / revocability reasons)

## 5. Documentation

- [x] 5.1 Update `src/operations/sod-remediation/README.md` workflow keys: search strings are revocable role and entitlement ids; access profiles are not parent access items; residual AP re-grant after entitlement revoke is out of scope
- [x] 5.2 Note in README that bundled `workflows/SOD Violation - Remediation.json` is unchanged (Get Access already includes entitlements); existing form instances keep old search strings until relaunch

## 6. Changelog

- [x] 6.1 Create or update changelog entry via **changelog-generator** during apply
- [x] 6.2 Confirm entry covers identity SoD revoke targets (entitlements/roles, not access profiles) and identity-access listing change
