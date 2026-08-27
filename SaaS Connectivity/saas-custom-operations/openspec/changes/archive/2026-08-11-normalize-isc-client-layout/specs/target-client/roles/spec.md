## ADDED Requirements

### Requirement: Role entitlement listing

The isc roles module SHALL return entitlement ids granted by a role via `getRoleEntitlementsV1`.

#### Scenario: Entitlement ids returned

- **GIVEN** a configured `RolesApi` and role id `{roleId}`
- **WHEN** `listRoleEntitlementIds` is invoked
- **THEN** the function SHALL call `getRoleEntitlementsV1`
- **AND** SHALL return entitlement ids from the response
