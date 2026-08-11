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

### Requirement: Access token identity resolution

The connector SHALL provide a generic JWT helper under `src/isc/token-identity.ts` for resolving the invoking identity id from an access token. The helper SHALL NOT encode result-source or operation-specific provisioning policy.

#### Scenario: identity_id claim preferred

- **GIVEN** a JWT with `identity_id` and `sub` claims
- **WHEN** `resolveTokenIdentity` is invoked
- **THEN** the function SHALL return the `identity_id` value

#### Scenario: Invalid token rejected

- **GIVEN** a string that is not a decodable JWT
- **WHEN** `resolveTokenIdentity` is invoked
- **THEN** the function SHALL throw `ConnectorError`

### Requirement: Pre-SDK HTTP transport

The connector SHALL provide generic HTTP clients under `src/isc/` for ISC APIs not yet exposed on bundled `sailpoint-api-client`, sending header `X-SailPoint-Experimental: true` where required. These clients SHALL NOT reference custom command names or operation-specific form field keys in their public API or requirements.

#### Scenario: Violation fetched by ID

- **GIVEN** a valid access token with violation read scope or ownership
- **WHEN** a caller invokes the violations client with a violation ID
- **THEN** the client SHALL call `GET /violations/v1/{violationId}` with the experimental header
- **AND** SHALL parse owner, target identity, policy, and conflicting access criteria from the response

#### Scenario: Violation fetch failure surfaces error

- **GIVEN** the violations API returns 404 or 403
- **WHEN** a caller requests the violation
- **THEN** the client SHALL fail with a ConnectorError describing the HTTP status

#### Scenario: Controls listed

- **WHEN** a caller invokes the controls client
- **THEN** the client SHALL call `GET /controls/v1` with the experimental header
- **AND** SHALL return tenant compensating control records with id, name, and optional description


