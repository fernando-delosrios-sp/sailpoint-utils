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

The isc access-profiles module SHALL provide paginated listing of enabled access profiles with an optional ISC search filter string. Listing logic SHALL reside under `src/isc/access-profiles/` and SHALL NOT encode access-sod-remediation operation orchestration.

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
- **THEN** the function SHALL return deterministic canned access profiles suitable for access-sod-remediation tests
