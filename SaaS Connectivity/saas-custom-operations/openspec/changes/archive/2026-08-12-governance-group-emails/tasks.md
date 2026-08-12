## 1. SDK governance groups client

- [x] 1.1 Extend `src/framework/types.ts` and `src/framework/sdk-factory.ts` to expose `governanceGroups: GovernanceGroupsApi` on `ctx.sdk`
- [x] 1.2 Update offline/test-mode SDK stub in request context to no-op `listWorkgroupsV1` and `listWorkgroupMembersV1`
- [x] 1.3 Add unit test — connected factory returns configured `GovernanceGroupsApi` (scenario: Governance groups client configured for workgroup operations)

## 2. ISC governance-groups module

- [x] 2.1 Create `src/isc/governance-groups/index.ts` barrel and `find-workgroup-by-name.ts` with OData filter + escaping
- [x] 2.2 Create `list-workgroup-member-emails.ts` with pagination over `listWorkgroupMembersV1` and blank-email filtering
- [x] 2.3 Create `resolve-governance-group-emails.ts` orchestrator (name → emails)
- [x] 2.4 Add `src/isc/governance-groups/offline-data.ts` with canned group → emails map for test mode
- [x] 2.5 Unit tests — workgroup found by name (scenario: Workgroup found by name)
- [x] 2.6 Unit tests — workgroup not found throws ConnectorError (scenarios: Workgroup not found; Orchestrator fails when group missing)
- [x] 2.7 Unit tests — listWorkgroupsV1 API failure throws ConnectorError (scenario: API failure surfaces error)
- [x] 2.8 Unit tests — member emails extracted with blank filtering (scenario: Member emails extracted)
- [x] 2.9 Unit tests — paginated member fetch aggregates all pages (scenario: Large member sets paginated)
- [x] 2.10 Unit tests — listWorkgroupMembersV1 API failure throws ConnectorError (scenario: Member list API failure)
- [x] 2.11 Unit tests — end-to-end orchestrator returns emails (scenario: End-to-end resolution by name)

## 3. Governance group emails operation

- [x] 3.1 Create `src/operations/governance-group-emails/index.ts` with `command: 'custom:governance-group-emails'`, input `groupName`, output `governance-group-emails:emails`
- [x] 3.2 Implement handler — connected path calls isc orchestrator; offline path uses offline-data
- [x] 3.3 Implement missing/blank `groupName` validation with ConnectorError (scenario: Missing groupName rejected)
- [x] 3.4 Implement unknown group ConnectorError propagation (scenario: Unknown group name rejected)
- [x] 3.5 Persist `governance-group-emails:emails` via `ctx.persist` with namespaced output key (scenario: Output contract is emails array)
- [x] 3.6 Run `npm run codegen:schemas` to register command and sync `connector-spec.json` (scenario: Auto-discovery registration)
- [x] 3.7 Unit tests — happy path persists emails array (scenario: Operation invoked with required input)
- [x] 3.8 Unit tests — offline invoke returns canned emails (scenario: Offline invoke supported)

## 4. Payloads, README, and local invoke

- [x] 4.1 Add `src/operations/governance-group-emails/README.md` documenting command, input/output, workflow steps, token scopes (scenario: Operation README documents contract)
- [x] 4.2 Add invoke payloads under `payloads/` (offline + connected examples)
- [x] 4.3 Register payload handler in `scripts/call-op.ts` if required by project convention
- [x] 4.4 Run full `npm test` and confirm coverage thresholds (60% statements, 50% branches)

## 5. Documentation

- [x] 5.1 Update root README operations table with `custom:governance-group-emails`
- [x] 5.2 N/A — no separate API doc surface beyond operation README and connector-spec (mark complete with reason if unchanged)

## 6. Changelog

- [x] 6.1 Create or update CHANGELOG entry via changelog-generator skill
- [x] 6.2 Confirm entry covers `custom:governance-group-emails` capability and ISC governance-groups module
