## ADDED Requirements

### Requirement: Form definition lookup by name

The isc forms module SHALL provide a helper that searches tenant form definitions via `searchFormDefinitionsByTenantV1` filtered to an exact `name` and returns the matching definition id. The helper SHALL NOT create or patch a form definition. When no definition matches, the helper SHALL throw `ConnectorError`. Name values SHALL be OData-escaped in the filter.

#### Scenario: Existing name returns definition id

- **GIVEN** a configured Custom Forms client and form name `Access Model SOD Remediation`
- **AND** search returns a definition with id `fd-1`
- **WHEN** the lookup-by-name helper is invoked
- **THEN** it SHALL call `searchFormDefinitionsByTenantV1` with filters equivalent to `name eq "Access Model SOD Remediation"`
- **AND** SHALL return `fd-1`
- **AND** SHALL NOT call create or patch form definition APIs

#### Scenario: Missing name surfaced as ConnectorError

- **GIVEN** search returns no definition for the supplied name
- **WHEN** the lookup-by-name helper is invoked
- **THEN** the helper SHALL throw `ConnectorError` with a message suitable for failed invoke responses
- **AND** SHALL NOT call create or patch form definition APIs

#### Scenario: Name with quotes is escaped

- **GIVEN** form name `Team "Alpha"`
- **WHEN** the lookup-by-name helper is invoked
- **THEN** the search filter SHALL OData-escape the name
