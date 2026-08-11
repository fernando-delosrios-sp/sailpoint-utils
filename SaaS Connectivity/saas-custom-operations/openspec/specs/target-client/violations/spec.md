# target-client/violations Specification

## Purpose

Generic violations API wrappers under `src/isc/violations/` for ISC APIs not yet exposed on bundled `sailpoint-api-client`. Modules SHALL NOT reference custom command names or operation-specific form field keys in their public API or requirements.

## Requirements

### Requirement: Violation fetch by ID

The isc violations module SHALL fetch a policy violation by ID via pre-SDK HTTP transport, sending header `X-SailPoint-Experimental: true`.

#### Scenario: Violation fetched by ID

- **GIVEN** a valid access token with violation read scope or ownership
- **WHEN** a caller invokes `getViolationV1` with a violation ID
- **THEN** the client SHALL call `GET /violations/v1/{violationId}` with the experimental header
- **AND** SHALL parse owner, target identity, policy, and conflicting access criteria from the response

#### Scenario: Violation fetch failure surfaces error

- **GIVEN** the violations API returns 404 or 403
- **WHEN** a caller requests the violation
- **THEN** the client SHALL fail with a ConnectorError describing the HTTP status
