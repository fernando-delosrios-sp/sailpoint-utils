# target-client/identity-access Delta

## MODIFIED Requirements

### Requirement: Identity access item listing

The isc identity-access module SHALL list **roles** assigned to an identity for use by custom operations, supporting both SDK loopback and offline stub data. Runtime offline stub lookup data SHALL live in a dedicated `offline-data.ts` module separate from orchestration implementation files. The module SHALL NOT list assigned access profiles.

#### Scenario: SDK loopback listing

- **GIVEN** a valid apiUrl and token and a target identity id
- **WHEN** `fetchIdentityAccessItemsFromSdk` is invoked with configured SDK clients
- **THEN** the function SHALL delegate identity role assignment listing to the identity-history module
- **AND** SHALL delegate role entitlement resolution to the roles module
- **AND** SHALL return identity access items of type role including id, name, and granted entitlement ids when available
- **AND** SHALL NOT list assigned access profiles
- **AND** SHALL NOT call the access-profiles module

#### Scenario: Offline data listing

- **GIVEN** test mode or offline invocation without apiUrl and token
- **WHEN** `fetchIdentityAccessItemsOffline` is invoked for a target identity id
- **THEN** the function SHALL return deterministic offline access items suitable for local operation tests
- **AND** those items SHALL NOT include type access profile
- **AND** SHALL NOT call ISC APIs

#### Scenario: Offline stub in dedicated module

- **GIVEN** the identity-access module provides offline stub data for local invoke
- **WHEN** a developer locates the offline lookup map or canned access items
- **THEN** the data SHALL reside in `src/isc/identity-access/offline-data.ts`
- **AND** orchestration logic SHALL reside in a separate implementation file (for example `fetch-identity-access-items.ts`)
