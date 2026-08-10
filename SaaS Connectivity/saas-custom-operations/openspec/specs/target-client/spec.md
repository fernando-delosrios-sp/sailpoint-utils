## Purpose

ISC SDK loopback integration for custom operations. Legacy target client layer (`src/my-client.ts`) was removed; configuration and connectivity are handled per invocation via the standard input envelope and `ctx.sdk`.
## Requirements
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

### Requirement: No external target application client

The connector SHALL NOT require a separate target-application HTTP client for custom operations; ISC integration SHALL use SDK loopback only.

#### Scenario: Legacy mock client absent

- **GIVEN** the connector source tree
- **WHEN** a developer inspects target integration code
- **THEN** src/my-client.ts SHALL NOT exist and custom operations SHALL use ctx.sdk exclusively

### Requirement: Custom Forms API error surfacing

The connector SHALL surface Custom Forms API failures used by sod remediation as `ConnectorError` with a message describing the operation context and HTTP status when available.

#### Scenario: Form definition create failure

- **GIVEN** `createFormDefinitionV1` rejects or returns no definition id
- **WHEN** `ensureFormDefinition` is invoked
- **THEN** the function SHALL throw `ConnectorError` describing the form definition failure

#### Scenario: Form instance create failure

- **GIVEN** `createFormInstanceV1` rejects with an HTTP error or returns no `standAloneFormUrl`
- **WHEN** `createRemediationInstance` is invoked
- **THEN** the function SHALL throw `ConnectorError` describing the form instance failure
- **AND** SHALL include the HTTP status in the message when the underlying client exposes it

#### Scenario: Form search SDK rejection

- **GIVEN** `searchFormDefinitionsByTenantV1` rejects with an axios or SDK error
- **WHEN** `ensureFormDefinition` performs the search step
- **THEN** the function SHALL throw `ConnectorError` rather than propagating a raw axios error

