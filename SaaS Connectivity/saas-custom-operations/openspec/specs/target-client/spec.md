## Purpose

ISC SDK loopback integration for custom operations. Legacy target client layer (`src/my-client.ts`) was removed; configuration and connectivity are handled per invocation via the standard input envelope and `ctx.sdk`.

## Requirements

### Requirement: SDK loopback client factory

The connector SHALL pre-configure `sailpoint-api-client` instances from operation input `apiUrl` and `token`, exposing them on `RequestContext.sdk` for the duration of each custom operation invocation.

#### Scenario: Accounts client configured for persist

- **GIVEN** a custom operation receives valid apiUrl and token in its input envelope
- **WHEN** the handler accesses ctx.sdk.accounts
- **THEN** the client SHALL be configured for ISC loopback account create and read used by ctx.persist

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
