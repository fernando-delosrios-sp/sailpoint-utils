## ADDED Requirements

### Requirement: Form instance read by id

The isc forms module SHALL provide a helper to fetch a tenant form instance by id via `getFormInstanceByKeyV1` and return normalized `formInput` and `formData` string maps suitable for operation handlers.

#### Scenario: Flat formInput returned

- **GIVEN** a configured Custom Forms client and form instance id `fi-1`
- **WHEN** `getFormInstanceById` is invoked
- **THEN** the helper SHALL call `getFormInstanceByKeyV1`
- **AND** SHALL return parsed `formInput` and `formData` maps from the response

#### Scenario: formInstanceInputs normalized when present

- **GIVEN** a form instance response that exposes `formInstanceInputs` entries with `{ id, value }` objects instead of a flat `formInput` map
- **WHEN** `getFormInstanceById` normalizes the payload
- **THEN** it SHALL flatten declared input ids to string values in the returned `formInput` map

#### Scenario: API errors surfaced as ConnectorError

- **GIVEN** `getFormInstanceByKeyV1` rejects or returns no instance
- **WHEN** `getFormInstanceById` is invoked
- **THEN** the helper SHALL throw `ConnectorError` with a message suitable for failed invoke responses
