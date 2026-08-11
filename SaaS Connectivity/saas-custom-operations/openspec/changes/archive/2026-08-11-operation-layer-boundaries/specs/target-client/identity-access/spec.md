## ADDED Requirements

### Requirement: Identity access item listing

The isc identity-access module SHALL list access items assigned to an identity for use by custom operations, supporting both SDK loopback and offline test fixtures.

#### Scenario: SDK loopback listing

- **GIVEN** a valid apiUrl and token and a target identity id
- **WHEN** `fetchIdentityAccessItemsFromSdk` is invoked with configured SDK clients
- **THEN** the function SHALL return identity access items including type, id, name, and granted entitlement ids when available

#### Scenario: Offline fixture listing

- **GIVEN** test mode or offline invocation without apiUrl and token
- **WHEN** `fetchIdentityAccessItemsOffline` is invoked for a target identity id
- **THEN** the function SHALL return deterministic fixture access items suitable for local operation tests
- **AND** SHALL NOT call ISC APIs
