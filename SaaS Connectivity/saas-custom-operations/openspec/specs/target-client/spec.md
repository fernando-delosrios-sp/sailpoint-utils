## Purpose

ISC SDK loopback integration for custom operations. Legacy target client layer (`src/my-client.ts`) was removed; configuration and connectivity are handled per invocation via the standard input envelope and `ctx.sdk`.

## Requirements

### Requirement: SDK loopback client factory

The connector SHALL pre-configure `sailpoint-api-client` instances from operation input `apiUrl` and `token`, exposing them on `RequestContext.sdk` for the duration of each custom operation invocation. The factory SHALL include clients for access requests, access profiles, entitlements, roles, identities, governance groups, SOD policies, SOD violations, IAI recommendations, and IAI outliers in addition to accounts.

#### Scenario: Accounts client configured for persist

- **GIVEN** a custom operation receives valid apiUrl and token in its input envelope
- **WHEN** the handler accesses ctx.sdk.accounts
- **THEN** the client SHALL be configured for ISC loopback account create and read used by ctx.persist

#### Scenario: Extended ISC clients available on context

- **GIVEN** a custom operation receives valid apiUrl and token
- **WHEN** the handler accesses ctx.sdk for accessRequests, accessProfiles, entitlements, roles, identities, governanceGroups, sodPolicies, sodViolations, iaiRecommendations, or iaiOutliers
- **THEN** each client SHALL share the same apiUrl and token configuration from the invocation input

### Requirement: No external target application client

The connector SHALL NOT require a separate target-application HTTP client for custom operations; ISC integration SHALL use SDK loopback only.

#### Scenario: Legacy mock client absent

- **GIVEN** the connector source tree
- **WHEN** a developer inspects target integration code
- **THEN** src/my-client.ts SHALL NOT exist and custom operations SHALL use ctx.sdk exclusively

