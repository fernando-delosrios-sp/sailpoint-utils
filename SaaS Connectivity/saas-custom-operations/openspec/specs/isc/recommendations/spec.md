## Purpose

ISC Recommendations API integration for batch keep-recommendation lookups used by connector operations.

## Requirements

### Requirement: Batch keep recommendations client

The isc integration layer SHALL expose a function to fetch keep recommendations for one identity and multiple access item references via `POST /recommendations/v1/request`.

#### Scenario: Successful batch fetch

- **GIVEN** a valid `IscClientConfig` and a list of `{ identityId, item: { id, type } }` requests
- **WHEN** the recommendations client is invoked
- **THEN** it SHALL call the Recommendations API once with all requests
- **AND** SHALL return a map keyed by item id and type to recommendation values `YES`, `NO`, `MAYBE`, or `NOT_FOUND`

#### Scenario: Offline mode

- **GIVEN** invoke runs in offline mode without live API
- **WHEN** the recommendations client is invoked
- **THEN** it SHALL return canned recommendation data without network calls

#### Scenario: Error propagation to caller

- **GIVEN** the Recommendations API returns a non-success response
- **WHEN** the recommendations client is invoked
- **THEN** it SHALL throw or return an error result that the sod-remediation operation can catch and degrade silently
