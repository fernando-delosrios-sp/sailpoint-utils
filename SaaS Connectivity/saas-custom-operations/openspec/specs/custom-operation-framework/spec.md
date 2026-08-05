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

The framework SHALL provide persist(id, attributes?, status?, options?) on a RequestContext typed to the operation output signature. The attributes parameter SHALL accept Partial of the operation output type. The framework SHALL always set id, sourceId, date, and status; author-supplied keys matching those names SHALL be ignored. The framework SHALL serialize attribute values for ISC storage: strings as-is, primitives via String(), arrays and objects via JSON.stringify, omitting null and undefined keys. The options parameter SHALL accept `{ verify?: boolean }` where verify defaults to true. When verify is true, the framework SHALL read the account back from ISC and verify persisted attributes match the values written before returning control. When verify is false, the framework SHALL skip inline read-back but SHALL record the written attributes for later batch verification.

#### Scenario: Persist with default status and timestamp

- **GIVEN** a request context typed to an output with outcome string and count number
- **WHEN** ctx.persist('req-001', { outcome: 'processed', count: 42 }) is called
- **THEN** the framework SHALL create an account with identity req-001, status success, date set, outcome processed, and count 42
- **AND** the framework SHALL verify read-back status, outcome, and count match before resolving

#### Scenario: Persist with typed output attributes and default status

- **GIVEN** a request context typed to an output with outcome string and count number
- **WHEN** ctx.persist('req-001', { outcome: 'processed', count: 42 }) is called
- **THEN** the framework SHALL create an account with identity req-001, status success, date set, outcome processed, and count 42
- **AND** the framework SHALL verify read-back status, outcome, and count match before resolving

#### Scenario: Persist with explicit status override

- **GIVEN** a request context typed to an output with errorCode string
- **WHEN** ctx.persist('req-001:err', { errorCode: 'timeout' }, 'failed') is called
- **THEN** the framework SHALL create an account with status failed and errorCode timeout
- **AND** the framework SHALL verify read-back status failed and errorCode timeout before resolving

#### Scenario: Persist with sparse params

- **GIVEN** a valid typed request context
- **WHEN** ctx.persist('req-001') is called with no attributes
- **THEN** the framework SHALL create an account with identity req-001, status success, and date set
- **AND** the framework SHALL verify status on read-back without requiring unset output attributes

#### Scenario: Persist with no attributes

- **GIVEN** a valid typed request context
- **WHEN** ctx.persist('req-001') is called with no attributes
- **THEN** the framework SHALL create an account with identity req-001, status success, and date set
- **AND** the framework SHALL verify status on read-back

#### Scenario: Persist upserts duplicate identity

- **GIVEN** an account with identity req-001 already exists on the dummy source
- **WHEN** ctx.persist('req-001', { outcome: 'updated' }) is called again
- **THEN** the framework SHALL upsert the account via account create without error
- **AND** the framework SHALL verify read-back outcome is updated before resolving

#### Scenario: Persist serializes array and object values

- **GIVEN** a request context typed to an output with name string and emails string array
- **WHEN** ctx.persist('req-001', { name: 'Fernando', emails: ['dfas', 'fasdfas'] }) is called
- **THEN** the framework SHALL store name as Fernando and emails as a JSON-serialized string
- **AND** the framework SHALL verify read-back name and emails match serialized values

#### Scenario: Persist ignores reserved framework keys in attributes

- **GIVEN** a request context typed to an output with outcome string
- **WHEN** ctx.persist('req-001', { id: 'override', status: 'override', outcome: 'ok' }) is called
- **THEN** the framework SHALL set id and status from framework logic
- **AND** the framework SHALL persist outcome ok

#### Scenario: Positional param mapping

- **GIVEN** a request context typed to an output with fieldA string, fieldB string, and fieldC string
- **WHEN** ctx.persist('req-001', { fieldA: 'a', fieldB: 'b', fieldC: 'c' }) is called
- **THEN** the framework SHALL persist fieldA, fieldB, and fieldC as named account attributes
- **AND** the framework SHALL verify read-back fieldA, fieldB, and fieldC match a, b, and c

#### Scenario: Persist retries read until account is available

- **GIVEN** account create succeeds but the account is not immediately readable from ISC
- **WHEN** ctx.persist('req-001', { outcome: 'value' }) is called
- **THEN** the framework SHALL retry reading the account with bounded attempts before failing verification

#### Scenario: Persist rejects when account cannot be verified

- **GIVEN** account create succeeds but read-back never returns a matching account within retry limits
- **WHEN** ctx.persist('req-001', { outcome: 'value' }) is called
- **THEN** the persist call SHALL reject with an error indicating verification failed for identity req-001

#### Scenario: Persist rejects on attribute mismatch

- **GIVEN** account create succeeds but read-back returns an account with status or output attribute values that differ from what was written
- **WHEN** ctx.persist('req-001', { outcome: 'expected' }, 'success') is called
- **THEN** the persist call SHALL reject with an error indicating which attributes failed verification

#### Scenario: Persist skips inline verification when verify is false

- **GIVEN** a valid typed request context
- **WHEN** ctx.persist('req-001', { outcome: 'value' }, undefined, { verify: false }) is called
- **THEN** the framework SHALL create the account without inline read-back verification
- **AND** the framework SHALL record expected attributes for identity req-001 in the write registry

### Requirement: Batch persist verification

The framework SHALL provide verifyPersisted(ids) on the request context that reads and verifies a list of account identities previously written via persist in the same invocation.

#### Scenario: Batch verify succeeds for deferred writes

- **GIVEN** ctx.persist('req-001', { outcome: 'a' }, undefined, { verify: false }) and ctx.persist('req-001:child', { outcome: 'b' }, undefined, { verify: false }) were called
- **WHEN** ctx.verifyPersisted(['req-001', 'req-001:child']) is called
- **THEN** the framework SHALL verify attributes match recorded expectations for all identities

#### Scenario: Batch verify rejects on missing account

- **GIVEN** an identity was written with verify false but is not readable within retry limits
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

The framework SHALL provide customOperation to wrap custom command handlers with context initialization and standard input parsing.

#### Scenario: Handler receives context and input

- **GIVEN** a handler registered via customOperation with an OperationSignature type parameter
- **WHEN** ISC invokes the custom command
- **THEN** the handler SHALL receive a RequestContext whose persist method accepts Partial of the operation output type
- **AND** the handler SHALL receive parsed operation input typed from the signature input field

### Requirement: Operation signature

Each custom operation SHALL declare an OperationSignature interface with input and output fields using plain TypeScript types. The framework SHALL provide customOperation to register the handler; input and ctx.persist attribute types SHALL be inferred from that interface at compile time.

#### Scenario: Operation declares combined input and output signature

- **GIVEN** an operation defines interface ExampleOperation extending OperationSignature with input message optional string and output summary string and optional step string
- **WHEN** the operation is registered via customOperation with a handler typed to ExampleOperation
- **THEN** the handler input parameter SHALL be typed as ExampleOperation input
- **AND** ctx.persist SHALL accept Partial of ExampleOperation output

