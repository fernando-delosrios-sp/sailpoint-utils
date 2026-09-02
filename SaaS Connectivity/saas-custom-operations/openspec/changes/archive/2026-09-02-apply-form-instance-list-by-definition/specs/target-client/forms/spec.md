## ADDED Requirements

### Requirement: Form instance list by definition and pick by id

The isc forms module SHALL provide a helper that lists tenant form instances via `searchFormInstancesByTenantV1` filtered to a form definition id, paginates with offset and limit, and returns the normalized instance whose id matches the caller-supplied form instance id. Normalization of `formInput` and `formData` SHALL match `getFormInstanceById`. When the instance is not found after the last page, the helper SHALL throw `ConnectorError`.

#### Scenario: Filter and pick

- **GIVEN** a configured Custom Forms client, form definition id `fd-1`, and form instance id `fi-1`
- **WHEN** the list-and-pick helper is invoked
- **THEN** it SHALL call `searchFormInstancesByTenantV1` with filters equivalent to `formDefinitionId eq "fd-1"`
- **AND** SHALL return the normalized instance for `fi-1` when present on any page

#### Scenario: Pagination continues until match or exhaustion

- **GIVEN** the matching instance is absent from the first full page
- **WHEN** the helper lists instances
- **THEN** it SHALL request further pages with increasing offset until the instance is found or a short page indicates the last page

#### Scenario: Missing instance surfaced as ConnectorError

- **GIVEN** no listed instance has the requested id
- **WHEN** pagination completes
- **THEN** the helper SHALL throw `ConnectorError` with a message suitable for failed invoke responses
