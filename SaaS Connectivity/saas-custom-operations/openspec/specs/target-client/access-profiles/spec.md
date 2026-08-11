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
