## 1. SDK client extensions

- [x] 1.1 Extend `src/framework/types.ts` and `src/framework/sdk-factory.ts` with `accessRequests`, `search`, and `sodViolations` on `SailPointClients`
- [x] 1.2 Update offline/test-mode `RequestContext` stubs for new SDK clients
- [x] 1.3 Unit test sdk-factory exposes AccessRequestsApi, SearchApi, and SODViolationsApi

## 2. ISC access-requests module

- [x] 2.1 Create `src/isc/access-requests/` with `listExecutingGrantAccessRequestsForIdentity` calling `listAccessRequestStatusV1` (EXECUTING + GRANT_ACCESS filter)
- [x] 2.2 Add `offline-data.ts` and offline list helper
- [x] 2.3 Unit tests: EXECUTING filter, GRANT_ACCESS-only filter, offline stub, barrel exports

## 3. ISC events-search module

- [x] 3.1 Create `src/isc/events-search/` with `searchEventsByTrackingNumber` via `SearchApi.searchPostV1` on `events` index
- [x] 3.2 Implement `searchEventsByTrackingNumberWithRetry` with bounded backoff
- [x] 3.3 Implement `extractAccessItemsFromEvents` (ENTITLEMENT, ROLE, ACCESS_PROFILE dedupe)
- [x] 3.4 Add offline fixtures and unit tests for search, retry success/empty, item extraction

## 4. ISC sod-prediction module

- [x] 4.1 Create `src/isc/sod-prediction/` with `predictSodViolationsForIdentity` calling `startPredictSodViolationsV1`
- [x] 4.2 Implement `parseViolatedPolicyNames` from ViolationPrediction response
- [x] 4.3 Implement `expandAccessItemsToEntitlementIds` delegating to roles/access-profiles modules
- [x] 4.4 Add empty-entitlement short-circuit and ConnectorError on API failure
- [x] 4.5 Add offline fixtures and unit tests for predict, parse, expansion, error paths

## 5. Situation summary builder

- [x] 5.1 Create `src/operations/preventive-sod-check/situation-summary.ts` with `buildPreventiveSituationSummary`
- [x] 5.2 Unit tests: no violations → `No violations found`; violations without accessRequestId list policies; violations with accessRequestId attribute request; summary fed mode-appropriate policy list

## 6. Preventive SOD check operation

- [x] 6.1 Create `src/operations/preventive-sod-check/index.ts` with `command: 'custom:preventive-sod-check'` and typed input/output (`identityId`, optional `accessRequestId` → namespaced persist fields including `has-violation`)
- [x] 6.2 Implement orchestration: list executing grants → events search with retry per trackingNumber → expand entitlements → differential predict when `accessRequestId` present → build summary → persist
- [x] 6.3 Handle no executing grants path (empty summary and policy array when no active violations)
- [x] 6.4 Ensure output excludes `approved` field
- [x] 6.5 Run codegen prebuild to register operation and sync connector-spec.json
- [x] 6.6 Unit/integration tests for handler happy paths, optional accessRequestId, offline invoke, auto-registration

## 7. Fixtures and local invoke

- [x] 7.1 Add operation payload under `payloads/preventive-sod-check.json`
- [x] 7.2 Register handler in `scripts/call-op.ts` for offline invoke
- [x] 7.3 Add `src/operations/preventive-sod-check/README.md` with invoke contract and workflow usage
- [x] 7.4 Run `npm test` and confirm coverage thresholds

## 8. Documentation

- [x] 8.1 Update root README with `custom:preventive-sod-check` invoke contract, inputs, and persisted output field names
- [x] 8.2 Document PAT scope requirements (access request read, search/events, SoD predict, violations read) in operation README
- [x] 8.3 Update inline JSDoc on public isc module exports (access-requests, events-search, sod-prediction, violations)

## 9. Changelog

- [x] 9.1 Create or update changelog entry via changelog-generator skill for new preventive SOD check operation
- [x] 9.2 Confirm entry covers user-visible change: workflow can branch on `preventive-sod-check:has-violation`, `preventive-sod-check:situation-summary`, and `preventive-sod-check:violated-policy-names`

## 10. Output morphology (attribution contract)

- [x] 10.1 Add `src/isc/violations/list-active-policy-names.ts` and offline stub for active violations by identity
- [x] 10.2 Add `src/isc/sod-prediction/policy-name-sets.ts` for union/delta policy name sets
- [x] 10.3 Refactor `pending-grants.ts` to `evaluatePreventiveSod` with identity vs request mode semantics
- [x] 10.4 Persist `preventive-sod-check:has-violation` and update operation README/CHANGELOG for dual-mode contract
- [x] 10.5 Update OpenSpec delta specs for morphology and violations list-by-identity helper
- [x] 10.6 Unit tests for active violations list, differential predict, and request-mode delta scenarios
