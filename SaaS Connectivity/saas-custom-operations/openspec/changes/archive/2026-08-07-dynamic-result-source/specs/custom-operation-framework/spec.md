## ADDED Requirements

### Requirement: Result source resolution by name

The framework SHALL resolve the configured sourceName to an ISC source ID at the start of each custom operation invocation using SourcesApi.

#### Scenario: Existing source resolved by name

- **GIVEN** an ISC source named Results Store exists
- **WHEN** a custom operation is invoked with sourceName Results Store
- **THEN** the framework SHALL set sourceId on the request context to that source's ID
- **AND** the handler SHALL proceed without creating a new source

#### Scenario: Missing source auto-created

- **GIVEN** no ISC source exists with the configured sourceName
- **WHEN** a custom operation is invoked
- **THEN** the framework SHALL create a DelimitedFile source with provisionAsCsv true and the configured name
- **AND** the source owner SHALL be the identity associated with the access token
- **AND** the framework SHALL set sourceId on the request context to the created source ID

#### Scenario: Duplicate source name on concurrent create

- **GIVEN** two invocations attempt to create the same sourceName concurrently
- **WHEN** one create succeeds and the other receives a conflict
- **THEN** the framework SHALL re-list sources by name and use the existing source ID

### Requirement: Schema reconciliation at persist

The framework SHALL reconcile the result source account schema before each ctx.persist call, scoped to the current operation's output contract and the keys present in the attributes argument.

#### Scenario: Missing output attribute added to schema

- **GIVEN** the account schema on the result source lacks attribute summary
- **AND** the current operation output includes summary string
- **WHEN** ctx.persist is called with attributes containing summary
- **THEN** the framework SHALL add summary to the account schema before creating the account

#### Scenario: Core framework attributes always present

- **GIVEN** a newly created result source
- **WHEN** ctx.persist is called for any operation
- **THEN** the account schema SHALL include id status and date attributes
- **AND** identityAttribute SHALL be id

#### Scenario: Type conflict warns and keeps existing

- **GIVEN** the account schema defines count as STRING
- **AND** the current operation output defines count as number
- **WHEN** ctx.persist is called with count 42
- **THEN** the framework SHALL log a warning about the type conflict
- **AND** SHALL NOT change the existing count attribute type
- **AND** SHALL proceed with account creation

#### Scenario: isMulti conflict patched to true

- **GIVEN** the account schema defines tags as STRING with isMulti false
- **AND** the current operation output defines tags as string array
- **WHEN** ctx.persist is called with tags containing values
- **THEN** the framework SHALL log a warning about the isMulti conflict
- **AND** SHALL patch the schema to set tags isMulti true
- **AND** SHALL proceed with account creation

### Requirement: Typed schema inference

The framework SHALL infer ISC account schema attribute definitions from OperationSignature output TypeScript types using the following mapping: string to STRING isMulti false, number to INT isMulti false, boolean to BOOLEAN isMulti false, bigint to LONG isMulti false, Date to DATE isMulti false, object or unknown to STRING isMulti false, array types to the element type mapping with isMulti true.

#### Scenario: Number output infers INT attribute

- **GIVEN** an operation output field count with type number
- **WHEN** schema reconciliation runs for that field
- **THEN** the inferred attribute SHALL have type INT and isMulti false

#### Scenario: String array output infers STRING multi attribute

- **GIVEN** an operation output field tags with type string array
- **WHEN** schema reconciliation runs for that field
- **THEN** the inferred attribute SHALL have type STRING and isMulti true

## MODIFIED Requirements

### Requirement: Volatile request context

The framework SHALL initialize a RequestContext at the start of each custom operation invocation and discard it when the handler completes.

#### Scenario: Context initialized from standard input

- **GIVEN** a custom operation receives input containing apiUrl, token, requestId, and sourceName
- **WHEN** the operation handler begins execution via withCustomOperation
- **THEN** the framework SHALL expose requestId and sourceName on the context
- **AND** SHALL expose the resolved sourceId after source resolution

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
- **AND** ctx.sdk.sources SHALL provide SourcesApi for source and schema management

### Requirement: Result persistence helper

The framework SHALL provide persist(id, attributes?, status?, options?) on a RequestContext typed to the operation output signature. Before creating the account, the framework SHALL reconcile the result source schema for the current operation. The attributes parameter SHALL accept Partial of the operation output type. The framework SHALL always set id, sourceId, date, and status; author-supplied keys matching those names SHALL be ignored. The framework SHALL format attribute values for ISC storage using typed inference: strings booleans numbers bigint and Date stored as native values matching their ISC types, objects and unknown values JSON-serialized to STRING, arrays stored per element type rules with isMulti true on schema. The options parameter SHALL accept verify boolean where verify defaults to true. When verify is true, the framework SHALL read the account back and verify persisted attributes match written values with type-aware comparison before returning control. When verify is false, the framework SHALL skip inline read-back but SHALL record written attributes for later batch verification.

#### Scenario: Persist stores typed number value

- **GIVEN** a request context typed to an output with count number
- **WHEN** ctx.persist('req-001', { count: 42 }) is called
- **THEN** the framework SHALL create an account with count stored as 42
- **AND** the framework SHALL verify read-back count equals 42 before resolving

#### Scenario: Persist stores boolean value

- **GIVEN** a request context typed to an output with active boolean
- **WHEN** ctx.persist('req-001', { active: true }) is called
- **THEN** the framework SHALL create an account with active stored as true
- **AND** the framework SHALL verify read-back active equals true before resolving

#### Scenario: Persist serializes object values

- **GIVEN** a request context typed to an output with meta Record string unknown
- **WHEN** ctx.persist('req-001', { meta: { key: 'value' } }) is called
- **THEN** the framework SHALL store meta as a JSON-serialized string
- **AND** the framework SHALL verify read-back meta matches the serialized value

#### Scenario: Persist with default status and timestamp

- **GIVEN** a request context typed to an output with outcome string
- **WHEN** ctx.persist('req-001', { outcome: 'processed' }) is called
- **THEN** the framework SHALL create an account with identity req-001, status success, date set, and outcome processed
- **AND** the framework SHALL verify read-back status and outcome match before resolving

#### Scenario: Persist with typed output attributes and default status

- **GIVEN** a request context typed to an output with outcome string and count number
- **WHEN** ctx.persist('req-001', { outcome: 'processed', count: 42 }) is called
- **THEN** the framework SHALL create an account with identity req-001, status success, date set, outcome processed, and count 42
- **AND** the framework SHALL verify read-back status, outcome, and count match before resolving

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

#### Scenario: Persist with explicit status override

- **GIVEN** a request context typed to an output with errorCode string
- **WHEN** ctx.persist('req-001:err', { errorCode: 'timeout' }, 'failed') is called
- **THEN** the framework SHALL create an account with status failed and errorCode timeout
- **AND** the framework SHALL verify read-back status failed and errorCode timeout before resolving

#### Scenario: Persist upserts duplicate identity

- **GIVEN** an account with identity req-001 already exists on the result source
- **WHEN** ctx.persist('req-001', { outcome: 'updated' }) is called again
- **THEN** the framework SHALL upsert the account via account create without error
- **AND** the framework SHALL verify read-back outcome is updated before resolving

#### Scenario: Persist serializes array and object values

- **GIVEN** a request context typed to an output with name string and emails string array
- **WHEN** ctx.persist('req-001', { name: 'Fernando', emails: ['dfas', 'fasdfas'] }) is called
- **THEN** the framework SHALL store name as Fernando and emails as the string array
- **AND** the framework SHALL verify read-back name and emails match before resolving

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

The framework SHALL provide verifyPersisted(ids) on the request context that reads and verifies a list of account identities previously written via persist in the same invocation using type-aware comparison.

#### Scenario: Batch verify succeeds for deferred writes

- **GIVEN** ctx.persist('req-001', { outcome: 'a' }, undefined, { verify: false }) and ctx.persist('req-001:child', { outcome: 'b' }, undefined, { verify: false }) were called
- **WHEN** ctx.verifyPersisted(['req-001', 'req-001:child']) is called
- **THEN** the framework SHALL verify attributes match recorded expectations for all identities

#### Scenario: Batch verify rejects on attribute mismatch

- **GIVEN** an identity was written with verify false but read-back attributes differ from recorded expectations
- **WHEN** ctx.verifyPersisted(['req-001']) is called
- **THEN** the call SHALL reject with an error indicating which attributes failed verification

#### Scenario: Batch verify rejects on missing account

- **GIVEN** an identity was written with verify false but is not readable within retry limits
- **WHEN** ctx.verifyPersisted(['req-001']) is called
- **THEN** the call SHALL reject with an error indicating verification failed for identity req-001

#### Scenario: Batch verify rejects unknown identity

- **GIVEN** identity req-999 was not written via ctx.persist in the current invocation
- **WHEN** ctx.verifyPersisted(['req-999']) is called
- **THEN** the call SHALL reject with an error indicating req-999 was not persisted in this invocation

