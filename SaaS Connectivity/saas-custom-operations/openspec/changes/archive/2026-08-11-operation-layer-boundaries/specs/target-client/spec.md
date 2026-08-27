## ADDED Requirements

### Requirement: Pre-SDK HTTP transport

The connector SHALL provide generic HTTP clients under `src/isc/` for ISC APIs not yet exposed on bundled `sailpoint-api-client`, sending header `X-SailPoint-Experimental: true` where required. These clients SHALL NOT reference custom command names or operation-specific form field keys in their public API or requirements.

#### Scenario: Violation fetched by ID

- **GIVEN** a valid access token with violation read scope or ownership
- **WHEN** a caller invokes the violations client with a violation ID
- **THEN** the client SHALL call `GET /violations/v1/{violationId}` with the experimental header
- **AND** SHALL parse owner, target identity, policy, and conflicting access criteria from the response

#### Scenario: Violation fetch failure surfaces error

- **GIVEN** the violations API returns 404 or 403
- **WHEN** a caller requests the violation
- **THEN** the client SHALL fail with a ConnectorError describing the HTTP status

#### Scenario: Controls listed

- **WHEN** a caller invokes the controls client
- **THEN** the client SHALL call `GET /controls/v1` with the experimental header
- **AND** SHALL return tenant compensating control records with id, name, and optional description

## REMOVED Requirements

### Requirement: Custom Forms API error surfacing

**Reason**: Generic Custom Forms client requirements move to the `target-client/forms` sub-capability. Root target-client SHALL NOT reference operation-specific forms helper names.

**Migration**: Equivalent scenarios are specified under `openspec/specs/target-client/forms/spec.md` using generic API names (`ensureFormDefinitionByName`, `createStandaloneFormInstance`).
