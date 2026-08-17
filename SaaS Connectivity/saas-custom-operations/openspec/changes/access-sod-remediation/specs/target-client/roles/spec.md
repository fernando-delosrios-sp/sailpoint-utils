## ADDED Requirements

### Requirement: Enabled roles listing with search filter

The isc roles module SHALL provide paginated listing of enabled roles with an optional ISC search filter string. Listing logic SHALL reside under `src/isc/roles/` and SHALL NOT encode access-sod-remediation operation orchestration.

#### Scenario: List all enabled roles

- **GIVEN** a configured RolesApi client and scope `"*"`
- **WHEN** `listEnabledRoles` is invoked
- **THEN** the function SHALL paginate through role list results
- **AND** SHALL return only enabled roles

#### Scenario: List roles with name filter

- **GIVEN** scope filter `name sw "Finance-"`
- **WHEN** `listEnabledRoles` is invoked
- **THEN** the function SHALL apply the filter in addition to the enabled constraint

#### Scenario: Offline stub role list

- **GIVEN** offline/testMode invocation
- **WHEN** `listEnabledRolesOffline` is invoked
- **THEN** the function SHALL return deterministic canned roles suitable for access-sod-remediation tests
