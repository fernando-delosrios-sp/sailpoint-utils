## ADDED Requirements

### Requirement: Test mode activation

The framework SHALL activate test mode when config testMode is true or when environment variable SPCX_TEST_MODE equals 1 and config testMode is not explicitly false.

#### Scenario: Test mode enabled via config

- **GIVEN** invoke config contains testMode true
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL operate in test mode for that invocation

#### Scenario: Test mode enabled via environment fallback

- **GIVEN** SPCX_TEST_MODE is 1 and config does not set testMode
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL operate in test mode for that invocation

#### Scenario: Test mode disabled by default

- **GIVEN** config omits testMode and SPCX_TEST_MODE is not 1
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL NOT operate in test mode
- **AND** persistence behavior SHALL match the existing production path

### Requirement: Inhibited ISC persistence in test mode

When test mode is active, the framework SHALL NOT call ISC account create, account read-back verification for persist, source auto-provision, or schema reconciliation APIs. ctx.persist and ctx.verifyPersisted SHALL remain callable with unchanged signatures.

#### Scenario: Persist does not create ISC account

- **GIVEN** test mode is active
- **WHEN** the handler calls ctx.persist with an identity and attributes
- **THEN** the framework SHALL NOT invoke createAccountV1
- **AND** the persist call SHALL resolve without error

#### Scenario: VerifyPersisted does not read ISC accounts

- **GIVEN** test mode is active and ctx.persist was called for identity req-001
- **WHEN** the handler calls ctx.verifyPersisted with req-001
- **THEN** the framework SHALL NOT invoke listAccountsV1 for verification
- **AND** the call SHALL resolve without error

#### Scenario: Source auto-provision inhibited in test mode

- **GIVEN** test mode is active with a valid access token and no existing source for sourceName
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL NOT call createSourceV1
- **AND** SHALL set sourceId to a placeholder value and log that source was not found

### Requirement: Token-gated ISC status checks in test mode

When test mode is active and config provides a non-empty access token and apiUrl, the framework SHALL perform read-only ISC connectivity validation before the handler runs. When test mode is active and no access token is provided, the framework SHALL skip all ISC API calls.

#### Scenario: ISC status checked when token provided

- **GIVEN** test mode is active and config contains a non-empty token and apiUrl
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL call a read-only ISC API to verify connectivity and token validity
- **AND** SHALL fail with ConnectorError when the status check fails

#### Scenario: ISC status logged on success

- **GIVEN** test mode is active with a valid token and successful ISC status check
- **WHEN** customOperation completes initialization
- **THEN** console output SHALL include a test-mode log line indicating ISC status check succeeded

#### Scenario: All ISC calls skipped without token

- **GIVEN** test mode is active and config token is absent or empty
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL NOT call any ISC API
- **AND** SHALL set sourceId to a fixed placeholder value for the invocation

#### Scenario: Source resolved read-only when token provided

- **GIVEN** test mode is active with a valid token and an existing ISC source matching sourceName
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL resolve sourceId via list-only lookup
- **AND** SHALL NOT auto-provision a missing source

### Requirement: Relaxed config in test mode without token

When test mode is active and no access token is provided, the framework SHALL require only requestId in input and SHALL treat apiUrl token and sourceName as optional config fields.

#### Scenario: Minimal offline fixture accepted

- **GIVEN** test mode is active and config omits token and apiUrl
- **WHEN** input contains requestId and a custom operation is invoked
- **THEN** the framework SHALL initialize the request context without ConnectorError for missing token

### Requirement: Test mode persistence console logging

When test mode is active, the framework SHALL log each inhibited persist and verifyPersisted operation to console with a test-mode prefix including identity, status, and formatted attributes.

#### Scenario: Inhibited persist logged with attributes

- **GIVEN** test mode is active
- **WHEN** ctx.persist is called with identity req-001 and attributes containing outcome processed
- **THEN** console output SHALL include a test-mode log line for identity req-001
- **AND** SHALL include the formatted attributes that would have been written

#### Scenario: Test mode startup and summary logged

- **GIVEN** test mode is active
- **WHEN** a custom operation starts and completes
- **THEN** console output SHALL log that test mode is active at start
- **AND** SHALL log a summary of inhibited persist count at completion

#### Scenario: Token not logged in test mode output

- **GIVEN** test mode is active and config contains a token
- **WHEN** the framework logs test mode messages
- **THEN** the token value SHALL NOT appear in console output

### Requirement: Unchanged res.send in test mode

When test mode is active, ctx.res SHALL remain the SDK Response object and handler calls to ctx.res.send SHALL behave identically to non-test-mode invocations.

#### Scenario: res.send invoked normally

- **GIVEN** test mode is active
- **WHEN** the handler calls ctx.res.send with a payload
- **THEN** the response object SHALL receive the payload through the standard SDK send mechanism
