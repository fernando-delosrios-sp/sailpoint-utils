## 1. SDK client extensions

- [x] 1.1 Extend `src/framework/types.ts` and `src/framework/sdk-factory.ts` with SodPolicies API (or pre-SDK HTTP client) on `SailPointClients`
- [x] 1.2 Update offline/test-mode `RequestContext` stubs for sod-policies client
- [x] 1.3 Unit test sdk-factory exposes sod-policies client alongside roles, accessProfiles, customForms

## 2. ISC sod-policies module

- [x] 2.1 Create `src/isc/sod-policies/` with paginated `listSodPolicies` and `getSodPolicy`
- [x] 2.2 Implement `parsePolicyQuerySides` (AND between sides, OR within `@access` clauses)
- [x] 2.3 Implement `resolvePolicySides` with `conflictingAccessCriteria` fallback and skip when unresolvable
- [x] 2.4 Implement `resolvePolicyOwnerId` from `ownerRef` (IDENTITY type v1)
- [x] 2.5 Add `offline-data.ts` and unit tests for list, get, parse, fallback, owner, offline stubs

## 3. ISC roles listing

- [x] 3.1 Add `listEnabledRoles` with pagination and optional scope filter to `src/isc/roles/`
- [x] 3.2 Add offline list helper and unit tests

## 4. ISC access-profiles listing

- [x] 4.1 Add `listEnabledAccessProfiles` with pagination and optional scope filter to `src/isc/access-profiles/`
- [x] 4.2 Add offline list helper and unit tests

## 5. Access item entitlement expansion

- [x] 5.1 Create operation helper to expand ROLE (direct + nested AP entitlements) and ACCESS_PROFILE to flat entitlement id set
- [x] 5.2 Unit tests for role with nested AP, standalone AP, deduplication

## 6. Violation detection orchestration

- [x] 6.1 Implement `detectAccessItemViolations` — cross product of items × policies with intersection logic
- [x] 6.2 Unit tests: both sides match, one side only, policyQuery parse, criteria fallback, skip unresolvable policy

## 7. Form seed and form service

- [x] 7.1 Create bundled seed `src/operations/access-sod-remediation/seed/access-sod-remediation.seed.json` (Correct-only side select, context section for access item + policy, group A/B HTML columns)
- [x] 7.2 Implement `form-service.ts` — ensure definition by name, build formInput, create instance, idempotency check for ASSIGNED instances
- [x] 7.3 Implement group HTML builder (entitlement lists; optional nested AP grouping labels)
- [x] 7.4 Unit tests for formInput assembly and idempotency skip logic

## 8. Access SOD remediation operation handler

- [x] 8.1 Create `src/operations/access-sod-remediation/index.ts` with typed input/output and `command: 'custom:access-sod-remediation'`
- [x] 8.2 Orchestrate: discover items → load policies → detect violations → create forms (cap 100) → parent/child persist
- [x] 8.3 Validate `searchIndices` values; default `scope`, `searchIndices`, `policyScope`
- [x] 8.4 Run codegen prebuild to register operation and sync connector-spec.json
- [x] 8.5 Handler unit/integration tests: parent rollup, child persist keys, offline invoke, cap, skip duplicate

## 9. Fixtures and local invoke

- [x] 9.1 Add `payloads/access-sod-remediation-offline.json`
- [x] 9.2 Register handler in `scripts/call-op.ts` for offline invoke
- [x] 9.3 Add `src/operations/access-sod-remediation/README.md` with invoke contract, parent/child read pattern, form submit contract, PAT scopes
- [x] 9.4 Run `npm test` and confirm coverage thresholds

## 10. Documentation and changelog

- [x] 10.1 Update root README with `custom:access-sod-remediation` summary and link to operation README
- [x] 10.2 Update CHANGELOG via changelog-generator skill for new operation
- [ ] 10.3 Update OpenSpec main specs on archive (connector-operations/access-sod-remediation, target-client/sod-policies, roles, access-profiles deltas)
