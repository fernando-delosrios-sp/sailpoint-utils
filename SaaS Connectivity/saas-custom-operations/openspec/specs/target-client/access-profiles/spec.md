# target-client/access-profiles Specification

## Purpose

Generic AccessProfilesApi wrappers under `src/isc/access-profiles/`. Callers supply access profile ids; this module SHALL NOT encode operation-specific access path assembly.

## Requirements

### Requirement: Access profile entitlement listing

The isc access-profiles module SHALL return entitlement ids granted by an access profile via `getAccessProfileEntitlementsV1`.

#### Scenario: Entitlement ids returned

- **GIVEN** a configured `AccessProfilesApi` and access profile id `{accessProfileId}`
- **WHEN** `listAccessProfileEntitlementIds` is invoked
- **THEN** the function SHALL call `getAccessProfileEntitlementsV1`
- **AND** SHALL return entitlement ids from the response

### Requirement: Enabled access profiles listing with search filter

The isc access-profiles module SHALL provide paginated listing of enabled access profiles with an optional ISC search filter string. Listing logic SHALL reside under `src/isc/access-profiles/` and SHALL NOT encode access-model-sod-remediation operation orchestration.

#### Scenario: List all enabled access profiles

- **GIVEN** a configured AccessProfilesApi client and scope `"*"`
- **WHEN** `listEnabledAccessProfiles` is invoked
- **THEN** the function SHALL paginate through access profile list results
- **AND** SHALL return only enabled access profiles

#### Scenario: List access profiles with name filter

- **GIVEN** scope filter `name sw "SAP-"`
- **WHEN** `listEnabledAccessProfiles` is invoked
- **THEN** the function SHALL apply the filter in addition to the enabled constraint

#### Scenario: Offline stub access profile list

- **GIVEN** offline/testMode invocation
- **WHEN** `listEnabledAccessProfilesOffline` is invoked
- **THEN** the function SHALL return deterministic canned access profiles suitable for access-model-sod-remediation tests

### Requirement: Access profile catalog patch helpers

The isc access-profiles module SHALL provide helpers to mutate access profile entitlements and description via `getAccessProfileV1` and `patchAccessProfileV1` without encoding access-model-sod-remediation-apply orchestration.

#### Scenario: Remove access profile entitlements

- **GIVEN** access profile `ap-v` entitlements `{ent-1, ent-2}` and caller requests removal `{ent-1}`
- **WHEN** `removeAccessProfileEntitlements` is invoked
- **THEN** the helper SHALL PATCH access profile `ap-v` so entitlements no longer include `ent-1`

#### Scenario: Append access profile description

- **GIVEN** access profile `ap-v` with existing description text
- **WHEN** `appendAccessProfileDescription` is invoked with an audit line
- **THEN** the helper SHALL PATCH access profile `ap-v` description by appending the audit line
