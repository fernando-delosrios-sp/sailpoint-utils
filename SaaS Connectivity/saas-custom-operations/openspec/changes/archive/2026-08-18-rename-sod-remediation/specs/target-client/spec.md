## MODIFIED Requirements

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

#### Scenario: Access model SOD remediation clients available on context

- **GIVEN** a custom operation receives valid apiUrl and token in its input envelope
- **WHEN** the access-model-sod-remediation handler accesses ISC APIs
- **THEN** `ctx.sdk` SHALL expose configured SodPolicies (or equivalent), RolesApi, AccessProfilesApi, and CustomFormsApi instances
- **AND** SHALL reuse existing entitlement expansion helpers under roles and access-profiles modules
