## 1. policyScope safety

- [x] 1.1 Fix `resolveSodPolicyListFilters` — reject unsupported state-bearing scopes; never unfiltered fallback
- [x] 1.2 Extend `policy-list-filter.spec.ts` with compound state rejection and name-only pass-through
- [x] 1.3 Ensure `listSodPolicies` surfaces ConnectorError to caller

## 2. Failure counters

- [x] 2.1 Add `access-model-sod-remediation:forms-launch-failed` output field
- [x] 2.2 Restrict `forms-persist-failed` to child persist catch only
- [x] 2.3 Update operation schema codegen, index.spec.ts, README

## 3. Scan performance caches

- [x] 3.1 Load assigned form instances once per scan; refactor `hasAssignedRemediationInstance`
- [x] 3.2 Add per-scan owner email memoization
- [x] 3.3 Add per-scan entitlement expansion cache in expand helper or scan loop
- [x] 3.4 Connected test with SDK mocks asserting bounded form search call count

## 4. Apply idempotency

- [x] 4.1 Check prior apply persist / terminal status before PATCH
- [x] 4.2 Extend invocation dedupe key to include formInstanceId for apply command
- [x] 4.3 Add `skipped-already-applied` status path with tests
- [x] 4.4 Update apply README and workflow notes

## 5. Test backfill

- [x] 5.1 Add `expand-access-item-entitlements.spec.ts`
- [x] 5.2 Add MAX_FORMS_PER_RUN cap test in access-model index.spec.ts
- [x] 5.3 Add `sod-remediation/form-service.spec.ts` mirroring access-model patterns
- [x] 5.4 Add sod-remediation enrichment failure swallowing characterization test

## 6. Verification

- [x] 6.1 Confirm canonical test command: `npm test`
- [x] 6.2 All delta spec scenarios covered by named automated tests

## 7. Documentation

- [x] 7.1 Update access-model-sod-remediation README for new counter and cache behavior notes
- [x] 7.2 Update access-model-sod-remediation-apply README for idempotency status

## 8. Changelog

- [x] 8.1 Create or update changelog entry for this change
- [x] 8.2 Confirm entry covers policyScope, counters, perf, apply idempotency
