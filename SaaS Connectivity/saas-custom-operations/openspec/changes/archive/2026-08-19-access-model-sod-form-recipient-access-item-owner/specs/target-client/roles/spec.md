## ADDED Requirements

### Requirement: Role owner identity extraction

The isc roles module SHALL extract the primary role owner identity id from a role `owner` reference for callers that need an IDENTITY form recipient. Extraction logic SHALL reside under `src/isc/roles/` and SHALL NOT encode access-model-sod-remediation orchestration.

#### Scenario: Role owner identity extraction

- **GIVEN** role `role-r` has `owner.type` `IDENTITY` (or omitted type) and `owner.id` `item-owner-1`
- **WHEN** `resolveRoleOwnerId` is invoked with that role owner reference (or after fetching the role)
- **THEN** the function SHALL return `item-owner-1`

#### Scenario: Missing role owner fails

- **GIVEN** role `role-r` has no `owner.id`
- **WHEN** `resolveRoleOwnerId` is invoked
- **THEN** the function SHALL throw ConnectorError indicating the role has no owner identity

#### Scenario: Non-IDENTITY role owner fails

- **GIVEN** role `role-r` has `owner.type` other than `IDENTITY` with an id present
- **WHEN** `resolveRoleOwnerId` is invoked
- **THEN** the function SHALL throw ConnectorError indicating IDENTITY is required
