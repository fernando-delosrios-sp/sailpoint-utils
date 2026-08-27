## 1. Shared pre-SDK HTTP transport

- [x] 1.1 Create `src/isc/http/isc-get.ts` with `IscClientConfig`, `iscGet`, and `EXPERIMENTAL_HEADER`
- [x] 1.2 Add unit coverage for HTTP failure surfacing via violations or controls tests

## 2. Pre-SDK API modules

- [x] 2.1 Create `src/isc/violations/` with `getViolationV1`, normalization helpers, and barrel export
- [x] 2.2 Add `src/isc/violations/violations.spec.ts` covering violation fetch, normalization shapes, and HTTP failure (target-client/violations scenarios)
- [x] 2.3 Create `src/isc/controls/` with `listControlsV1` and barrel export
- [x] 2.4 Add `src/isc/controls/controls.spec.ts` covering controls list scenario

## 3. SDK API modules (identity access split)

- [x] 3.1 Create `src/isc/identity-history/list-assigned-access-items.ts` and spec (access profile + role listing scenarios)
- [x] 3.2 Create `src/isc/access-profiles/access-profile-entitlements.ts` and spec (entitlement ids scenario)
- [x] 3.3 Create `src/isc/roles/role-entitlements.ts` and spec (entitlement ids scenario)
- [x] 3.4 Create `src/isc/identity-access/` orchestration module delegating to 3.1–3.3; move offline data
- [x] 3.5 Add `src/isc/identity-access/identity-access.spec.ts` covering SDK loopback and offline data scenarios

## 4. Token identity relocation

- [x] 4.1 Move `token-identity.ts` and spec to `src/isc/token-identity/`
- [x] 4.2 Update framework exports and imports (`framework/index.ts`, `result-source.ts`)

## 5. Consumer import updates and cleanup

- [x] 5.1 Update `src/operations/sod-remediation/` imports to new isc paths
- [x] 5.2 Update sod-remediation test mocks for violations, controls, identity-access paths
- [x] 5.3 Delete deprecated flat files: `identity-access-client.ts`, `isc-client.ts`, root `token-identity.ts` and their specs
- [x] 5.5 Add `index.ts` barrel to every ISC API folder missing one (forms, sources, identity-history, access-profiles, roles, token-identity, http)
- [x] 5.6 Update consumer imports to use folder entry paths where applicable

## 6. Verification

- [x] 6.1 Run `npm test` — all tests pass
- [x] 6.2 Run `npm run build` — build succeeds

## 7. Documentation

- [x] 7.1 Update README layout section with per-API subdirectory rule and `http/` transport note
- [x] 7.2 Confirm target-client spec deltas align with implemented paths (no stale `experimental/` references)

## 8. Changelog

- [x] 8.1 Create or update changelog entry for ISC client layout normalization (invoke changelog-generator if available)
- [x] 8.2 Confirm entry covers non-breaking refactor and new module paths for extenders
