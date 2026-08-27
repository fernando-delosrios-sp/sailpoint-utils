## ADDED Requirements

### Requirement: ConnectorError propagation for custom operations

The framework SHALL ensure every failure escaping a `customOperation`-wrapped handler is a `ConnectorError` from `@sailpoint/connector-sdk`. Errors that are already `ConnectorError` SHALL be rethrown unchanged. All other errors — including plain `Error`, axios rejections from `sailpoint-api-client`, and `PersistVerificationError` — SHALL be converted to `ConnectorError` before propagating to the connector runtime.

#### Scenario: Handler throws plain Error

- **GIVEN** a custom operation handler that throws `new Error('operation failed')`
- **WHEN** ISC invokes the custom command via `customOperation`
- **THEN** the invocation SHALL reject with an error that is an instance of `ConnectorError`
- **AND** the error message SHALL include the original failure message

#### Scenario: Initialization failure before handler runs

- **GIVEN** test mode is active with provided config and ISC status check rejects with a plain SDK error
- **WHEN** `customOperation` initializes the request context
- **THEN** the invocation SHALL reject with `ConnectorError`
- **AND** SHALL NOT propagate the raw SDK error type unchanged

#### Scenario: Persist verification failure

- **GIVEN** a handler calls `ctx.persist` and account read-back verification fails after bounded retries
- **WHEN** the persist helper throws `PersistVerificationError`
- **THEN** the invocation SHALL reject with `ConnectorError` describing the verification failure

#### Scenario: Existing ConnectorError preserved

- **GIVEN** a handler or framework helper throws `new ConnectorError('missing field')`
- **WHEN** the error propagates through `customOperation`
- **THEN** the same `ConnectorError` instance or equivalent type and message SHALL be rethrown without double-wrapping

#### Scenario: HTTP 404 maps to NotFound type

- **GIVEN** an ISC client call fails with HTTP status 404
- **WHEN** the error is normalized by the framework
- **THEN** the resulting `ConnectorError` SHALL have type `notFound`
