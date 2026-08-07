## Purpose

Custom operation framework (`src/framework/`) providing request context, SDK loopback, result persistence, logging, and the withCustomOperation wrapper for custom command handlers.
## Requirements
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

Each custom operation SHALL declare an OperationSignature interface with input and output fields using plain TypeScript types. The interface MAY optionally declare `command?: string` as a string literal for build-time auto-registration. The framework SHALL provide customOperation to register the handler; input and ctx.persist attribute types SHALL be inferred from that interface at compile time.

#### Scenario: Operation declares command for auto-registration

- **GIVEN** an operation defines `interface ExampleOperation extends OperationSignature` with `command: 'custom:example'`, input, and output fields
- **WHEN** codegen runs
- **THEN** the operation SHALL be included in the generated auto-registry without manual index.ts registration

#### Scenario: Operation declares combined input and output signature

- **GIVEN** an operation defines interface ExampleOperation extending OperationSignature with input message optional string and output summary string and optional step string
- **WHEN** the operation is registered via customOperation with a handler typed to ExampleOperation
- **THEN** the handler input parameter SHALL be typed as ExampleOperation input
- **AND** ctx.persist SHALL accept Partial of ExampleOperation output

### Requirement: Operation schema contract on context

The framework SHALL attach an OperationSchemaContract to the request context containing the current command name and output fields from the operation's OperationSignature. For auto-discovered operations, the framework SHALL resolve the schema from a build-time populated registry keyed by command name when `operationSchema` is not passed explicitly to `customOperation`. Manually registered operations SHALL continue to pass an explicit `operationSchema` sidecar. Operation modules SHALL NOT hand-maintain duplicate `defineOperationSchema({...})` field maps.

#### Scenario: Context carries current operation output fields

- **GIVEN** `custom:example` declares output fields `summary` string and optional `step` string in its OperationSignature interface
- **AND** `example-operation.schema.ts` is generated from that interface
- **AND** the sidecar is registered via generated `auto-registry.ts`
- **WHEN** `custom:example` is invoked
- **THEN** the request context operationSchema SHALL include `summary` and `step` as output fields for schema reconciliation

#### Scenario: Auto-discovered operation resolves schema from registry

- **GIVEN** `custom:example` is auto-discovered and its generated sidecar is registered via `registerOperationSchema`
- **AND** the handler is created via `customOperation<ExampleOperation>(handler)` without an explicit `operationSchema` option
- **WHEN** `custom:example` is invoked
- **THEN** the request context operationSchema SHALL include output fields from the generated sidecar for schema reconciliation

#### Scenario: Auto-discovered operation wires sidecar via auto-registry

- **GIVEN** `example-operation.ts` declares `command: 'custom:example'` on its OperationSignature interface
- **AND** codegen generates `example-operation.schema.ts` and `auto-registry.ts`
- **WHEN** the generated auto-registry is loaded
- **THEN** it SHALL import `exampleOperationSchema` from `./example-operation.schema`
- **AND** SHALL call `registerOperationSchema('custom:example', exampleOperationSchema)`
- **AND** `example-operation.ts` SHALL NOT inline a manual `defineOperationSchema({...})` field map

#### Scenario: Manual operation requires explicit operationSchema

- **GIVEN** a manually registered operation without `command` on its OperationSignature
- **WHEN** the handler is registered via `customOperation` with `{ operationSchema: manualOperationSchema }`
- **THEN** the request context operationSchema SHALL use the explicitly passed schema

#### Scenario: Explicit operationSchema overrides registry

- **GIVEN** an auto-discovered operation also passes `{ operationSchema: customSchema }` to `customOperation`
- **WHEN** the operation is invoked
- **THEN** the explicit schema SHALL take precedence over the registry lookup

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

