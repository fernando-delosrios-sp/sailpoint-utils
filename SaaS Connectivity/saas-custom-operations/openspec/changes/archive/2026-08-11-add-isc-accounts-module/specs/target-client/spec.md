## MODIFIED Requirements

### Requirement: ISC module layout by API grouping

The connector SHALL organize generic ISC integration code under `src/isc/<api-grouping>/` subdirectories aligned to `sailpoint-api-client` API classes or individual ISC REST API surfaces. A module SHALL NOT combine wrappers for unrelated API clients in one file. Pre-SDK APIs SHALL NOT be grouped under a shared umbrella folder such as `experimental/`.

#### Scenario: Per-API subdirectory present

- **GIVEN** the connector source tree under `src/isc/`
- **WHEN** a developer inspects ISC integration modules
- **THEN** forms, sources, accounts, violations, controls, identity-history, access-profiles, roles, identity-access, and token-identity SHALL each reside in their own subdirectory
- **AND** flat handler files directly under `src/isc/` (other than shared barrels if present) SHALL NOT be used for ISC client implementations

#### Scenario: Identity access APIs separated

- **GIVEN** identity access listing requires IdentityHistoryApi, AccessProfilesApi, and RolesApi
- **WHEN** a developer inspects isc integration modules
- **THEN** IdentityHistoryApi wrappers SHALL live under `src/isc/identity-history/`
- **AND** AccessProfilesApi wrappers SHALL live under `src/isc/access-profiles/`
- **AND** RolesApi wrappers SHALL live under `src/isc/roles/`
- **AND** cross-API orchestration SHALL live under `src/isc/identity-access/` only

#### Scenario: Account schema vs instance separation

- **GIVEN** ISC account schemas are managed via SourcesApi and account instances via AccountsApi
- **WHEN** a developer inspects isc integration modules
- **THEN** account schema wrappers SHALL live under `src/isc/sources/`
- **AND** account instance wrappers SHALL live under `src/isc/accounts/`

### Requirement: ISC API folder barrel entry

Each ISC client API folder under `src/isc/<api-grouping>/` SHALL provide an `index.ts` that re-exports or implements the public API surface for that grouping. Consumers SHOULD import from the folder entry (`../../isc/<api-grouping>`) rather than deep module paths.

#### Scenario: index.ts present in every API folder

- **GIVEN** the connector source tree under `src/isc/`
- **WHEN** a developer inspects an ISC client API folder (forms, sources, accounts, violations, controls, identity-history, access-profiles, roles, identity-access, or token-identity)
- **THEN** the folder SHALL contain `index.ts`
- **AND** `index.ts` SHALL export the public functions and types required by operations and framework code for that API grouping

#### Scenario: Barrel exports match implemented API calls

- **GIVEN** an ISC client API folder with one or more implementation modules
- **WHEN** a developer reads `index.ts` for that folder
- **THEN** every public API function and type intended for external use SHALL be exported from `index.ts`
- **AND** `index.ts` SHALL NOT export operation-specific or internal-only helpers
