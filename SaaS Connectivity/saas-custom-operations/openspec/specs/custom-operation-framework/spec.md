## Purpose

Custom operation framework (`src/framework/`) providing request context, SDK loopback, result persistence, logging, and the withCustomOperation wrapper for custom command handlers.

## Requirements

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

The framework SHALL provide persist(id, params?, status?, options?) on the request context that writes an account to the dummy source identified by sourceId. The options parameter SHALL accept `{ verify?: boolean }` where verify defaults to true. When verify is true, the framework SHALL read the account back from ISC and verify persisted attributes match the values written before returning control. When verify is false, the framework SHALL skip inline read-back but SHALL record the written attributes for later batch verification. The framework SHALL record expected attributes for every persist call regardless of the verify option.

#### Scenario: Persist with default status and timestamp

- **GIVEN** a valid request context with sourceId configured
- **WHEN** ctx.persist('req-001', ['processed', '42']) is called
- **THEN** the framework SHALL create an account with identity req-001, status success, date set to current timestamp, param1 processed, and param2 42
- **AND** the framework SHALL read the account back and verify status, date, param1, and param2 match before the persist call resolves

#### Scenario: Persist with explicit status override

- **GIVEN** a valid request context
- **WHEN** ctx.persist('req-001:err', ['timeout'], 'failed') is called
- **THEN** the framework SHALL create an account with identity req-001:err and status failed
- **AND** the framework SHALL verify the read-back account has status failed and param1 timeout before resolving

#### Scenario: Persist with sparse params

- **GIVEN** a valid request context
- **WHEN** ctx.persist('req-001') is called with no params
- **THEN** the framework SHALL create an account with identity req-001, status success, and date set, omitting unset param attributes
- **AND** the framework SHALL verify status and date on read-back without requiring unset param attributes

#### Scenario: Persist upserts duplicate identity

- **GIVEN** an account with identity req-001 already exists on the dummy source
- **WHEN** ctx.persist('req-001', ['updated']) is called again
- **THEN** the framework SHALL upsert the account via account create without error
- **AND** the framework SHALL verify read-back param1 is updated before resolving

#### Scenario: Positional param mapping

- **GIVEN** a valid request context
- **WHEN** ctx.persist('req-001', ['a', 'b', 'c']) is called
- **THEN** the framework SHALL map index 0 to param1, index 1 to param2, and index 2 to param3
- **AND** the framework SHALL verify param1, param2, and param3 on read-back match a, b, and c

#### Scenario: Persist retries read until account is available

- **GIVEN** account create succeeds but the account is not immediately readable from ISC
- **WHEN** ctx.persist('req-001', ['value']) is called
- **THEN** the framework SHALL retry reading the account with bounded attempts before failing verification
- **AND** the framework SHALL resolve once read-back attributes match the written values

#### Scenario: Persist rejects when account cannot be verified

- **GIVEN** account create succeeds but read-back never returns a matching account within retry limits
- **WHEN** ctx.persist('req-001', ['value']) is called
- **THEN** the persist call SHALL reject with an error indicating verification failed for identity req-001

#### Scenario: Persist rejects on attribute mismatch

- **GIVEN** account create succeeds but read-back returns an account with status or param values that differ from what was written
- **WHEN** ctx.persist('req-001', ['expected'], 'success') is called
- **THEN** the persist call SHALL reject with an error indicating which attributes failed verification

#### Scenario: Persist skips inline verification when verify is false

- **GIVEN** a valid request context
- **WHEN** ctx.persist('req-001', ['value'], undefined, { verify: false }) is called
- **THEN** the framework SHALL create the account without performing inline read-back verification
- **AND** the framework SHALL record the expected attributes for identity req-001 in the invocation write registry

### Requirement: Batch persist verification

The framework SHALL provide verifyPersisted(ids) on the request context that reads and verifies a list of account identities previously written via persist in the same invocation.

#### Scenario: Batch verify succeeds for deferred writes

- **GIVEN** ctx.persist('req-001', ['a'], undefined, { verify: false }) and ctx.persist('req-001:child', ['b'], undefined, { verify: false }) were called
- **WHEN** ctx.verifyPersisted(['req-001', 'req-001:child']) is called
- **THEN** the framework SHALL read each account back with bounded retry and verify attributes match the recorded expectations
- **AND** the call SHALL resolve when all identities pass verification

#### Scenario: Batch verify rejects on missing account

- **GIVEN** an identity was written with verify false but is not readable from ISC within retry limits
- **WHEN** ctx.verifyPersisted(['req-001']) is called
- **THEN** the call SHALL reject with an error indicating verification failed for identity req-001

#### Scenario: Batch verify rejects on attribute mismatch

- **GIVEN** an identity was written with verify false but read-back attributes differ from recorded expectations
- **WHEN** ctx.verifyPersisted(['req-001']) is called
- **THEN** the call SHALL reject with an error indicating which attributes failed verification

#### Scenario: Batch verify rejects unknown identity

- **GIVEN** identity req-999 was not written via ctx.persist in the current invocation
- **WHEN** ctx.verifyPersisted(['req-999']) is called
- **THEN** the call SHALL reject with an error indicating req-999 was not persisted in this invocation

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
