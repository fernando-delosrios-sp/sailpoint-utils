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

### Requirement: List active violation policy names for identity

The connector SHALL provide an ISC client helper that lists policy names from active SoD violations for a given identity using `GET /violations/v1` with the experimental header.

#### Scenario: List violations by identity filter

- **GIVEN** connected invoke config with valid `apiUrl` and `token`
- **WHEN** `listActiveViolationPolicyNamesForIdentity` is called for identity `{identityId}`
- **THEN** the client SHALL call `GET /violations/v1` with filter `identityId eq "{identityId}"`
- **AND** SHALL return deduplicated policy names from the response

#### Scenario: Offline stub returns canned policy names

- **GIVEN** offline preventive check for identity `offline-preventive-existing`
- **WHEN** the offline list helper runs
- **THEN** it SHALL return `["Existing Control"]` without calling ISC APIs

#### Scenario: Empty when no active violations offline

- **GIVEN** offline identity with no canned active violations
- **WHEN** the offline list helper runs
- **THEN** it SHALL return an empty array

