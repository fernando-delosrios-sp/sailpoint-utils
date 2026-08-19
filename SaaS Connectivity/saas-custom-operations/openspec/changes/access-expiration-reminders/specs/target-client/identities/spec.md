## ADDED Requirements

### Requirement: Search identities with sunset access profiles

The isc identities module SHALL provide a helper that searches for identities that have one or more ACCESS_PROFILE assignments with a `removeDate`, returning identity id, display name, manager id when present, and the sunset ACCESS_PROFILE assignment details needed for reminder matching (`id`, `name`, `source` name when available, `removeDate`). Runtime offline stub data SHALL live in `offline-data.ts` separate from orchestration implementation.

#### Scenario: SDK search returns sunset assignments

- **GIVEN** a valid Search API client and tenant data containing identities with ACCESS_PROFILE `removeDate` values
- **WHEN** the sunset search helper is invoked
- **THEN** it SHALL query the identities search index
- **AND** SHALL return identities including matching ACCESS_PROFILE assignment fields required by `custom:access-expiration-reminders`

#### Scenario: Offline fixtures available

- **GIVEN** offline invocation without live ISC APIs
- **WHEN** the offline sunset search helper is invoked
- **THEN** it SHALL return deterministic fixture identities with ACCESS_PROFILE `removeDate` values
- **AND** SHALL NOT call ISC APIs

### Requirement: Resolve identity manager id

The isc identities module SHALL resolve the manager identity id for a given identity from search/document fields used by reminder operations. When no manager id is present, resolution SHALL return no manager (callers skip).

#### Scenario: Manager id present

- **GIVEN** an identity document includes a manager identity reference id
- **WHEN** manager resolution runs
- **THEN** it SHALL return that manager id

#### Scenario: Manager id absent

- **GIVEN** an identity document has no manager reference
- **WHEN** manager resolution runs
- **THEN** it SHALL return no manager id

### Requirement: Identities module layout

The identities helpers SHALL reside under `src/isc/identities/` with an `index.ts` barrel. The module SHALL use SearchApi (and/or pre-SDK HTTP) without mixing unrelated API clients into the same implementation files.

#### Scenario: Identities subdirectory present

- **GIVEN** the connector source tree under `src/isc/`
- **WHEN** a developer inspects ISC integration modules
- **THEN** identities helpers SHALL reside in `src/isc/identities/`
- **AND** `index.ts` SHALL export the public search and manager-resolution functions
