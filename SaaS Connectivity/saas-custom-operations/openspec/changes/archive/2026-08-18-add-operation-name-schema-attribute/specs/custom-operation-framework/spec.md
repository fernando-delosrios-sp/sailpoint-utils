## ADDED Requirements

### Requirement: Operation name core account attribute

The framework SHALL include a mandatory STRING attribute named `operationName` on the result source base account schema alongside core attributes `id`, `status`, `date`, and `details`. Schema reconciliation at persist time SHALL ensure `operationName` exists on the account schema before writing any account. The `operationName` attribute SHALL NOT be generated from `OperationSignature.output` fields or operation schema sidecars.

#### Scenario: Base schema includes operationName on new source

- **GIVEN** no ISC source exists with the configured sourceName
- **WHEN** a custom operation invocation auto-creates the result source
- **THEN** the applied base account schema SHALL include attribute `operationName` with type STRING and isMulti false
- **AND** SHALL include attributes `id`, `status`, `date`, and `details`

#### Scenario: Persist reconciles missing operationName on existing source

- **GIVEN** a result source account schema lacks attribute `operationName`
- **WHEN** ctx.persist is called for any operation
- **THEN** the framework SHALL add `operationName` to the account schema before writing the account

#### Scenario: OperationName excluded from operation output codegen union

- **GIVEN** an operation declares output fields in its OperationSignature interface
- **WHEN** the templates generator builds reference account schema from the union of registered operation outputs
- **THEN** attribute `operationName` SHALL come only from framework core attributes
- **AND** SHALL NOT be duplicated from operation output field definitions

#### Scenario: Success persist sets operationName from command

- **GIVEN** a custom operation invoked with commandType `custom:example`
- **WHEN** ctx.persist('req-001', { outcome: 'done' }) is called
- **THEN** the written account SHALL include operationName `custom:example`

#### Scenario: Handler-supplied operationName ignored

- **GIVEN** a custom operation invoked with commandType `custom:example`
- **WHEN** ctx.persist('req-001', { outcome: 'done', operationName: 'custom:other' }) is called
- **THEN** the written account SHALL include operationName `custom:example`
- **AND** SHALL NOT store `custom:other`

---

## MODIFIED Requirements

### Requirement: Base account schema on result source create

When the framework auto-provisions a new DelimitedFile result source, it SHALL apply the **base account schema** immediately after source creation. The base schema SHALL include core framework attributes (`id`, `status`, `date`, `details`, `operationName`) plus the **output fields of the invoking custom operation** (from `operationSchema.outputFields` on the current invocation), excluding reserved framework keys, with typed inference matching templates generator and persist-time reconciliation rules.

If an account schema already exists on the newly created source (for example from ISC schema discovery), the framework SHALL align that schema to the base schema by adding missing attributes and correcting schema metadata (`identityAttribute`, `displayAttribute`, `nativeObjectType`, `name`) when absent or incorrect. The framework SHALL NOT remove existing attributes. Type and isMulti conflicts SHALL follow the same warn-only policy as persist-time schema reconciliation.

When `operationSchema` is unavailable at source create, the framework SHALL apply core framework attributes only and SHALL rely on persist-time reconciliation to add operation output fields on first `ctx.persist`.

#### Scenario: New source receives full base schema

- **GIVEN** no ISC source exists with the configured sourceName
- **AND** the invoking operation declares output fields `summary` and `step`
- **AND** other registered operations declare output field `violationId`
- **WHEN** a custom operation invocation auto-creates the result source
- **THEN** the framework SHALL create or align the account schema to include `id`, `status`, `date`, `details`, `operationName`, `summary`, and `step`
- **AND** the account schema SHALL NOT include `violationId` from other registered operations
- **AND** SHALL set `identityAttribute` to `id`

#### Scenario: ISC-discovered schema replaced with base schema

- **GIVEN** source create completes and ISC has already materialized an account schema with only discovered CSV columns
- **WHEN** the framework applies the base account schema for the invoking operation
- **THEN** the framework SHALL patch the existing account schema to add core attributes and the invoking operation's output fields including `details` and `operationName`
- **AND** SHALL NOT fail with a duplicate schema create error

#### Scenario: Base schema excludes reserved framework keys

- **GIVEN** the invoking operation output includes field `sourceId`
- **WHEN** base schema is applied on source create
- **THEN** the account schema SHALL NOT include attribute `sourceId`

#### Scenario: Existing result source unchanged

- **GIVEN** an ISC result source with the configured sourceName already exists
- **WHEN** a custom operation is invoked
- **THEN** the framework SHALL resolve the existing source ID
- **AND** SHALL NOT re-apply the base account schema

#### Scenario: Later operation adds fields via persist reconciliation

- **GIVEN** a result source was auto-created by operation A with only A's output fields on the schema
- **AND** operation B declares output field `violationId` not present on the schema
- **WHEN** operation B invokes and calls `ctx.persist` with attribute `violationId`
- **THEN** the framework SHALL add `violationId` to the account schema before writing the account

#### Scenario: Core-only base schema when operationSchema absent

- **GIVEN** no ISC source exists with the configured sourceName
- **AND** the invoking handler has no resolvable `operationSchema`
- **WHEN** a custom operation invocation auto-creates the result source
- **THEN** the applied base account schema SHALL include only `id`, `status`, `date`, `details`, and `operationName`

---

### Requirement: Result persistence helper

The framework SHALL provide persist(id, attributes?, status?, options?) on a RequestContext typed to the operation output signature. Before writing the account, the framework SHALL reconcile the result source schema for the current operation. The attributes parameter SHALL accept Partial of the operation output type. The framework SHALL always set id, sourceId, date, and status; when the invocation command is known, the framework SHALL always set operationName from that command; author-supplied keys matching id, status, date, or operationName SHALL be ignored. The framework SHALL format attribute values for ISC storage using typed inference: strings booleans numbers bigint and Date stored as native values matching their ISC types, objects and unknown values JSON-serialized to STRING, arrays stored per element type rules with isMulti true on schema. Before writing, the framework SHALL enforce ISC account value limits: the persist identity (account id / nativeIdentity) SHALL NOT exceed 128 characters, and each STRING attribute value (including each element of a STRING array and JSON-serialized object values) SHALL NOT exceed 256 characters. Values exceeding a limit SHALL be truncated to the limit and the framework SHALL log a warning naming the attribute or identity context. The options parameter SHALL accept verify boolean where verify defaults to true. When no account exists for the identity on the result source, the framework SHALL create the account via createAccountV1, wait for the provisioning task to complete, and read the account back. When an account already exists for the identity, the framework SHALL update the account via putAccountV1, wait for the provisioning task when one is returned, and read the account back. The framework SHALL NOT remove existing accounts via deleteAccountAsyncV1 before writing. When verify is true, the framework SHALL read the account back and verify persisted attributes match written values with type-aware comparison before returning control. When verify is false, the framework SHALL skip inline read-back but SHALL record written attributes for later batch verification.

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

#### Scenario: Persist creates account when identity absent

- **GIVEN** no account with identity req-001 exists on the result source
- **WHEN** ctx.persist('req-001', { outcome: 'new' }) is called
- **THEN** the framework SHALL invoke createAccountV1
- **AND** the framework SHALL NOT invoke putAccountV1

#### Scenario: Persist upserts duplicate identity

- **GIVEN** an account with identity req-001 already exists on the result source with a resolvable ISC account id
- **WHEN** ctx.persist('req-001', { outcome: 'updated' }) is called again
- **THEN** the framework SHALL update the account via putAccountV1 with the updated attributes
- **AND** the framework SHALL NOT invoke deleteAccountAsyncV1
- **AND** the framework SHALL verify read-back outcome is updated before resolving

#### Scenario: Persist serializes array and object values

- **GIVEN** a request context typed to an output with name string and emails string array
- **WHEN** ctx.persist('req-001', { name: 'Fernando', emails: ['dfas', 'fasdfas'] }) is called
- **THEN** the framework SHALL store name as Fernando and emails as the string array
- **AND** the framework SHALL verify read-back name and emails match before resolving

#### Scenario: Persist ignores reserved framework keys in attributes

- **GIVEN** a request context typed to an output with outcome string
- **WHEN** ctx.persist('req-001', { id: 'override', status: 'override', operationName: 'custom:other', outcome: 'ok' }) is called
- **THEN** the framework SHALL set id, status, and operationName from framework logic
- **AND** the framework SHALL persist outcome ok

#### Scenario: Positional param mapping

- **GIVEN** a request context typed to an output with fieldA string, fieldB string, and fieldC string
- **WHEN** ctx.persist('req-001', { fieldA: 'a', fieldB: 'b', fieldC: 'c' }) is called
- **THEN** the framework SHALL persist fieldA, fieldB, and fieldC as named account attributes
- **AND** the framework SHALL verify read-back fieldA, fieldB, and fieldC match a, b, and c

#### Scenario: Persist retries read until account is available

- **GIVEN** account write succeeds but the account is not immediately readable from ISC
- **WHEN** ctx.persist('req-001', { outcome: 'value' }) is called
- **THEN** the framework SHALL retry reading the account with bounded attempts before failing verification

#### Scenario: Persist rejects when account cannot be verified

- **GIVEN** account write succeeds but read-back never returns a matching account within retry limits
- **WHEN** ctx.persist('req-001', { outcome: 'value' }) is called
- **THEN** the persist call SHALL reject with an error indicating verification failed for identity req-001

#### Scenario: Persist rejects on attribute mismatch

- **GIVEN** account write succeeds but read-back returns an account with status or output attribute values that differ from what was written
- **WHEN** ctx.persist('req-001', { outcome: 'expected' }, 'success') is called
- **THEN** the persist call SHALL reject with an error indicating which attributes failed verification

#### Scenario: Persist skips inline verification when verify is false

- **GIVEN** a valid typed request context
- **WHEN** ctx.persist('req-001', { outcome: 'value' }, undefined, { verify: false }) is called
- **THEN** the framework SHALL write the account without inline read-back verification
- **AND** the framework SHALL record expected attributes for identity req-001 in the write registry

#### Scenario: Identity truncated at 128 characters

- **GIVEN** a persist identity string longer than 128 characters
- **WHEN** ctx.persist is called with that identity
- **THEN** the framework SHALL store an account identity of exactly 128 characters equal to the first 128 characters of the supplied identity
- **AND** the framework SHALL log a warning that the identity was truncated

#### Scenario: STRING attribute truncated at 256 characters

- **GIVEN** a request context typed to an output with summary string
- **AND** summary value longer than 256 characters
- **WHEN** ctx.persist('req-001', { summary: '<long value>' }) is called
- **THEN** the framework SHALL store summary as exactly 256 characters equal to the first 256 characters of the input
- **AND** the framework SHALL log a warning naming summary

#### Scenario: STRING array elements truncated independently

- **GIVEN** a request context typed to an output with tags string array
- **AND** one tag element longer than 256 characters
- **WHEN** ctx.persist('req-001', { tags: ['ok', '<long tag>'] }) is called
- **THEN** the framework SHALL store the long tag truncated to 256 characters
- **AND** the framework SHALL store the short tag unchanged

#### Scenario: Values within limits unchanged

- **GIVEN** a persist identity of 64 characters and a STRING attribute of 200 characters
- **WHEN** ctx.persist is called with those values
- **THEN** the framework SHALL store identity and attribute values without truncation
- **AND** the framework SHALL NOT log a truncation warning

---

### Requirement: Schema reconciliation at persist

The framework SHALL reconcile the result source account schema before each ctx.persist call, scoped to the current operation's output contract and the keys present in the attributes argument.

#### Scenario: Missing output attribute added to schema

- **GIVEN** the account schema on the result source lacks attribute summary
- **AND** the current operation output includes summary string
- **WHEN** ctx.persist is called with attributes containing summary
- **THEN** the framework SHALL add summary to the account schema before creating the account

#### Scenario: Core framework attributes always present

- **GIVEN** a newly created result source with base schema applied
- **WHEN** ctx.persist is called for any operation
- **THEN** the account schema SHALL include id, status, date, details, and operationName attributes
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

---

### Requirement: Automatic failed account persist on terminal failure

The framework SHALL upsert a result source account for the invoke `requestId` with `status` failed, `details` set to the normalized failure message, and `operationName` set from the invocation command when known whenever a `customOperation`-wrapped invocation terminates with `{ status: 'failed', error }` on the command response and a request context with persist was initialized. This SHALL apply to handler throws normalized by `toConnectorError`, initialization failures before the handler completes, persist verification failures, and handler-initiated `res.send({ status: 'failed', error })` payloads. The framework SHALL perform this persist before or together with sending the failed invoke response. If failure persist itself errors, the framework SHALL log the error and SHALL still send the failed invoke response without throwing.

#### Scenario: Handler throw persists failed account

- **GIVEN** a custom operation handler throws `new Error('operation failed')`
- **AND** invoke input contains requestId `wf-run-001`
- **AND** the invocation commandType is `custom:example`
- **WHEN** ISC invokes the custom command via `customOperation`
- **THEN** the framework SHALL upsert an account with identity `wf-run-001`, status failed, details containing `operation failed`, and operationName `custom:example`
- **AND** the invoke response SHALL include status failed and error containing `operation failed`

#### Scenario: Handler sends failed response persists account

- **GIVEN** a handler calls `ctx.res.send({ status: 'failed', error: 'form create failed' })`
- **AND** invoke input contains requestId `wf-run-002`
- **AND** the invocation commandType is `custom:example`
- **WHEN** the custom command completes
- **THEN** the framework SHALL upsert an account with identity `wf-run-002`, status failed, details `form create failed`, and operationName `custom:example`

#### Scenario: Initialization failure persists failed account

- **GIVEN** test mode is active with provided config and ISC status check rejects
- **AND** invoke input contains requestId `wf-run-003`
- **WHEN** `customOperation` fails during request context initialization
- **THEN** the framework SHALL upsert a failed account for `wf-run-003` with details describing the initialization failure when persist is available
- **AND** the invoke response SHALL include status failed

#### Scenario: Persist verification failure persists failed account

- **GIVEN** a handler calls `ctx.persist('wf-run-004', { outcome: 'value' })` and verification fails
- **WHEN** `PersistVerificationError` is handled by `customOperation`
- **THEN** the framework SHALL upsert a failed account for identity `wf-run-004` with details describing the verification failure

#### Scenario: Failure persist failure is non-fatal

- **GIVEN** a handler throws and account upsert fails with an ISC error
- **WHEN** `customOperation` handles the terminal failure
- **THEN** the invoke response SHALL still include status failed with the original error message
- **AND** the invocation SHALL resolve without throwing

#### Scenario: Failed persist skips inline verification

- **GIVEN** a terminal failure triggers automatic failed account persist
- **WHEN** the framework writes the failed account
- **THEN** it SHALL NOT require inline read-back verification to succeed before sending the failed invoke response
