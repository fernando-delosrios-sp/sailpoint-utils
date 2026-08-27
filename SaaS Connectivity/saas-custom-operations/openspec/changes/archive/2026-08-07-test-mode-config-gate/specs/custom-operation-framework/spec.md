## ADDED Requirements

### Requirement: Config-gated ISC status checks in test mode

When test mode is active and an invocation config object is provided, the framework SHALL validate standard connection fields, perform read-only ISC connectivity validation before the handler runs, and fail when the token is missing, invalid, or when any read-only ISC call errors. When test mode is active and no invocation config is provided, the framework SHALL skip all ISC API calls.

#### Scenario: ISC status checked when config provided

- **GIVEN** test mode is active and an invocation config object is provided with apiUrl token and sourceName
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL call a read-only ISC API to verify connectivity and token validity
- **AND** SHALL fail with ConnectorError when the status check fails

#### Scenario: ISC status logged on success

- **GIVEN** test mode is active with provided config and a successful ISC status check
- **WHEN** customOperation completes initialization
- **THEN** console output SHALL include a test-mode log line indicating ISC status check succeeded

#### Scenario: All ISC calls skipped when no config provided

- **GIVEN** test mode is active via SPCX_TEST_MODE and no invocation config object is provided
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL NOT call any ISC API
- **AND** SHALL set sourceId to a fixed placeholder value for the invocation

#### Scenario: Source resolved read-only when config provided

- **GIVEN** test mode is active with provided config and an existing ISC source matching sourceName
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL resolve sourceId via list-only lookup
- **AND** SHALL NOT auto-provision a missing source

#### Scenario: Missing token fails when config provided

- **GIVEN** test mode is active and an invocation config object is provided without token
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL reject with ConnectorError indicating missing required config fields

### Requirement: Invocation config presence detection

The framework SHALL determine whether an invocation config object was provided from deps.config, context.config, or readConfig before applying test mode ISC gating.

#### Scenario: Context config counts as provided

- **GIVEN** test mode is active and context.config contains connection fields
- **WHEN** customOperation resolves configuration
- **THEN** the framework SHALL treat config as provided
- **AND** SHALL require apiUrl token and sourceName

#### Scenario: Absent config enables offline test mode path

- **GIVEN** test mode is active via SPCX_TEST_MODE only and neither deps.config nor context.config is set
- **WHEN** customOperation resolves configuration
- **THEN** the framework SHALL treat config as not provided
- **AND** SHALL skip ISC API calls

## REMOVED Requirements

### Requirement: Token-gated ISC status checks in test mode

**Reason**: Gate criterion changed from token presence to config presence; token-less partial config must not silently skip ISC.

**Migration**: Remove offline branches keyed on hasAccessToken. Provide config with full connection fields for read-only ISC, or omit config entirely and use SPCX_TEST_MODE for offline runs.

### Requirement: Relaxed config in test mode without token

**Reason**: Partial config with missing token must fail validation, not run offline.

**Migration**: Offline fixtures omit the config section and set SPCX_TEST_MODE=1. Do not pass config objects with only testMode.
