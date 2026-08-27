## ADDED Requirements

### Requirement: Volatile request context

The framework SHALL initialize a RequestContext at the start of each custom operation invocation and discard it when the handler completes.

#### Scenario: Context initialized from standard input

- **GIVEN** a custom operation receives input containing apiUrl, token, requestId, and sourceId
- **WHEN** the operation handler begins execution via withCustomOperation
- **THEN** the framework SHALL expose requestId and sourceId on the context

#### Scenario: Context is not shared across invocations

- **GIVEN** two sequential custom operation invocations with different requestId values
- **WHEN** each handler executes
- **THEN** each invocation SHALL receive an independent context with its own requestId

### Requirement: SDK loopback initialization

The framework SHALL pre-configure sailpoint-api-client instances on the request context using apiUrl and token from the operation input.

#### Scenario: SDK available without manual setup

- **GIVEN** a custom operation handler wrapped with withCustomOperation
- **WHEN** the handler accesses ctx.sdk
- **THEN** the SDK SHALL be configured for the provided apiUrl and token

### Requirement: Result persistence helper

The framework SHALL provide persist(id, params?, status?) on the request context that writes an account to the dummy source identified by sourceId.

#### Scenario: Persist with default status and timestamp

- **GIVEN** a valid request context with sourceId configured
- **WHEN** ctx.persist('req-001', ['processed', '42']) is called
- **THEN** the framework SHALL create an account with identity req-001, status success, date set to current timestamp, param1 processed, and param2 42

#### Scenario: Persist with explicit status override

- **GIVEN** a valid request context
- **WHEN** ctx.persist('req-001:err', ['timeout'], 'failed') is called
- **THEN** the framework SHALL create an account with identity req-001:err and status failed

#### Scenario: Persist with sparse params

- **GIVEN** a valid request context
- **WHEN** ctx.persist('req-001') is called with no params
- **THEN** the framework SHALL create an account with identity req-001, status success, and date set, omitting unset param attributes

#### Scenario: Persist upserts duplicate identity

- **GIVEN** an account with identity req-001 already exists on the dummy source
- **WHEN** ctx.persist('req-001', ['updated']) is called again
- **THEN** the framework SHALL upsert the account via account create without error

#### Scenario: Positional param mapping

- **GIVEN** a valid request context
- **WHEN** ctx.persist('req-001', ['a', 'b', 'c']) is called
- **THEN** the framework SHALL map index 0 to param1, index 1 to param2, and index 2 to param3

### Requirement: Operation logging

The framework SHALL provide correlated logging on the request context that includes requestId in every log entry.

#### Scenario: Logs include requestId correlation

- **GIVEN** a custom operation with requestId wf-run-8842
- **WHEN** the handler calls ctx.log.info with a message
- **THEN** the log output SHALL include requestId wf-run-8842

#### Scenario: Token is not logged

- **GIVEN** a custom operation input containing a token
- **WHEN** the handler or framework logs operation details
- **THEN** the token value SHALL NOT appear in log output

### Requirement: Custom operation wrapper

The framework SHALL provide withCustomOperation to wrap custom command handlers with context initialization and standard input parsing.

#### Scenario: Handler receives context and input

- **GIVEN** a handler function registered via withCustomOperation
- **WHEN** ISC invokes the custom command
- **THEN** the handler SHALL receive the request context and parsed operation input
