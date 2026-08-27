# target-client/identity-history Specification

## Purpose

Generic IdentityHistoryApi wrappers under `src/isc/identity-history/`. Callers supply identity ids and access item types; this module SHALL NOT encode operation-specific access path assembly or offline data policy.

## Requirements

### Requirement: Assigned access item listing

The isc identity-history module SHALL list access profiles or roles assigned to an identity via `listIdentityAccessItemsV1`.

#### Scenario: Access profiles listed for identity

- **GIVEN** a configured `IdentityHistoryApi` and identity id `{identityId}`
- **WHEN** `listAssignedAccessItems` is invoked with type `accessProfile`
- **THEN** the function SHALL call `listIdentityAccessItemsV1` with experimental flag enabled
- **AND** SHALL return assigned access profile records with id and display name when present

#### Scenario: Roles listed for identity

- **GIVEN** a configured `IdentityHistoryApi` and identity id `{identityId}`
- **WHEN** `listAssignedAccessItems` is invoked with type `role`
- **THEN** the function SHALL call `listIdentityAccessItemsV1` with type `role`
- **AND** SHALL return assigned role records with id and display name when present
