## Purpose

ISC SDK loopback integration for custom operations. Legacy target client layer (`src/my-client.ts`) was removed; configuration and connectivity are handled per invocation via the standard input envelope and `ctx.sdk`.

Generic ISC helpers live under `src/isc/<api-grouping>/` — one subdirectory per ISC API surface. Each subdirectory SHALL host thin wrappers for a single API client and MAY grow additional modules without mixing unrelated APIs. Shared pre-SDK HTTP transport utilities live under `src/isc/http/` and SHALL NOT group multiple API clients.
## Requirements
### Requirement: ISC module layout by API grouping

The connector SHALL organize generic ISC integration code under `src/isc/<api-grouping>/` subdirectories aligned to `sailpoint-api-client` API classes or individual ISC REST API surfaces. A module SHALL NOT combine wrappers for unrelated API clients in one file. Pre-SDK APIs SHALL NOT be grouped under a shared umbrella folder such as `experimental/`.

#### Scenario: Per-API subdirectory present

- **GIVEN** the connector source tree under `src/isc/`
- **WHEN** a developer inspects ISC integration modules
- **THEN** forms, sources, accounts, violations, controls, identity-history, access-profiles, roles, identity-access, token-identity, public-identities, recommendations, governance-groups, access-requests, events-search, and sod-prediction SHALL each reside in their own subdirectory
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

#### Scenario: Governance groups API separated

- **GIVEN** governance group lookup and member listing use GovernanceGroupsApi
- **WHEN** a developer inspects isc integration modules
- **THEN** GovernanceGroupsApi wrappers SHALL live under `src/isc/governance-groups/`
- **AND** SHALL NOT be mixed with public-identities or identity-access modules

### Requirement: ISC API folder barrel entry

Each ISC client API folder under `src/isc/<api-grouping>/` SHALL provide an `index.ts` that re-exports or implements the public API surface for that grouping. Consumers SHOULD import from the folder entry (`../../isc/<api-grouping>`) rather than deep module paths.

#### Scenario: index.ts present in every API folder

- **GIVEN** the connector source tree under `src/isc/`
- **WHEN** a developer inspects an ISC client API folder (forms, sources, accounts, violations, controls, identity-history, access-profiles, roles, identity-access, token-identity, public-identities, recommendations, or governance-groups)
- **THEN** the folder SHALL contain `index.ts`
- **AND** `index.ts` SHALL export the public functions and types required by operations and framework code for that API grouping

#### Scenario: Barrel exports match implemented API calls

- **GIVEN** an ISC client API folder with one or more implementation modules
- **WHEN** a developer reads `index.ts` for that folder
- **THEN** every public API function and type intended for external use SHALL be exported from `index.ts`
- **AND** `index.ts` SHALL NOT export operation-specific or internal-only helpers

### Requirement: SDK loopback client factory

The connector SHALL pre-configure `sailpoint-api-client` instances from operation input `apiUrl` and `token`, exposing them on `RequestContext.sdk` for the duration of each custom operation invocation.

#### Scenario: Accounts client configured for persist

- **GIVEN** a custom operation receives valid apiUrl and token in its input envelope
- **WHEN** the handler accesses ctx.sdk.accounts
- **THEN** the client SHALL be configured for ISC loopback account create, update, and read used by ctx.persist

#### Scenario: Sources client configured for result source management

- **GIVEN** a custom operation receives valid apiUrl and token in its input envelope
- **WHEN** the handler or framework accesses ctx.sdk.sources
- **THEN** the client SHALL be configured for source lookup, creation, and schema management used by dynamic result source provisioning

#### Scenario: Governance groups client configured for workgroup operations

- **GIVEN** a custom operation receives valid apiUrl and token in its input envelope
- **WHEN** the governance-group-emails handler or isc governance-groups module accesses ctx.sdk.governanceGroups
- **THEN** the client SHALL be a configured GovernanceGroupsApi instance for `listWorkgroupsV1` and `listWorkgroupMembersV1`

#### Scenario: Preventive SOD check clients available on context

- **GIVEN** a custom operation receives valid apiUrl and token in its input envelope
- **WHEN** the preventive-sod-check handler accesses ISC APIs
- **THEN** `ctx.sdk` SHALL expose configured `AccessRequestsApi`, `SearchApi`, and `SODViolationsApi` instances
- **AND** SHALL reuse existing `RolesApi` and `AccessProfilesApi` clients for entitlement expansion

### Requirement: No external target application client

The connector SHALL NOT require a separate target-application HTTP client for custom operations; ISC integration SHALL use SDK loopback only.

#### Scenario: Legacy mock client absent

- **GIVEN** the connector source tree
- **WHEN** a developer inspects target integration code
- **THEN** src/my-client.ts SHALL NOT exist and custom operations SHALL use ctx.sdk exclusively

### Requirement: Access token identity resolution

The connector SHALL provide a generic JWT helper under `src/isc/token-identity/` for resolving the invoking identity id from an access token. The helper SHALL NOT encode result-source or operation-specific provisioning policy.

#### Scenario: identity_id claim preferred

- **GIVEN** a JWT with `identity_id` and `sub` claims
- **WHEN** `resolveTokenIdentity` is invoked
- **THEN** the function SHALL return the `identity_id` value

#### Scenario: Invalid token rejected

- **GIVEN** a string that is not a decodable JWT
- **WHEN** `resolveTokenIdentity` is invoked
- **THEN** the function SHALL throw `ConnectorError`

