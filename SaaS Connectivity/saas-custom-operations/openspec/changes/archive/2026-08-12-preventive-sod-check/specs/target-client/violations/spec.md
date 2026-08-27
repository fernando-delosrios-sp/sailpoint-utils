# target-client/violations Delta

## ADDED Requirements

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
