## ADDED Requirements

### Requirement: Details core account attribute

The framework SHALL include a mandatory STRING attribute named `details` on the result source base account schema alongside core attributes `id`, `status`, and `date`. Schema reconciliation at persist time SHALL ensure `details` exists on the account schema before writing any account. The `details` attribute SHALL NOT be generated from `OperationSignature.output` fields or operation schema sidecars.

#### Scenario: Base schema includes details on new source

- **GIVEN** no ISC source exists with the configured sourceName
- **WHEN** a custom operation invocation auto-creates the result source
- **THEN** the applied base account schema SHALL include attribute `details` with type STRING and isMulti false
- **AND** SHALL include attributes `id`, `status`, and `date`

#### Scenario: Persist reconciles missing details on existing source

- **GIVEN** a result source account schema lacks attribute `details`
- **WHEN** ctx.persist is called for any operation
- **THEN** the framework SHALL add `details` to the account schema before writing the account

#### Scenario: Details excluded from operation output codegen union

- **GIVEN** an operation declares output fields in its OperationSignature interface
- **WHEN** base schema is built from the union of registered operation outputs
- **THEN** attribute `details` SHALL come only from framework core attributes
- **AND** SHALL NOT be duplicated from operation output field definitions

---

### Requirement: Automatic failed account persist on terminal failure

The framework SHALL upsert a result source account for the invoke `requestId` with `status` failed and `details` set to the normalized failure message whenever a `customOperation`-wrapped invocation terminates with `{ status: 'failed', error }` on the command response and a request context with persist was initialized. This SHALL apply to handler throws normalized by `toConnectorError`, initialization failures before the handler completes, persist verification failures, and handler-initiated `res.send({ status: 'failed', error })` payloads. The framework SHALL perform this persist before or together with sending the failed invoke response. If failure persist itself errors, the framework SHALL log the error and SHALL still send the failed invoke response without throwing.

#### Scenario: Handler throw persists failed account

- **GIVEN** a custom operation handler throws `new Error('operation failed')`
- **AND** invoke input contains requestId `wf-run-001`
- **WHEN** ISC invokes the custom command via `customOperation`
- **THEN** the framework SHALL upsert an account with identity `wf-run-001`, status failed, and details containing `operation failed`
- **AND** the invoke response SHALL include status failed and error containing `operation failed`

#### Scenario: Handler sends failed response persists account

- **GIVEN** a handler calls `ctx.res.send({ status: 'failed', error: 'form create failed' })`
- **AND** invoke input contains requestId `wf-run-002`
- **WHEN** the custom command completes
- **THEN** the framework SHALL upsert an account with identity `wf-run-002`, status failed, and details `form create failed`

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

---

### Requirement: Optional details on success persist

The framework SHALL allow handlers to supply an optional STRING `details` value when calling `ctx.persist` on success (or any non-failed status). When supplied, the framework SHALL store `details` on the written account attributes. When omitted on success, the framework SHALL NOT invent a default `details` value.

#### Scenario: Success persist with informative details

- **GIVEN** a handler calls `ctx.persist('wf-run-010', { outcome: 'done', details: 'Processed 3 of 5 items' })`
- **WHEN** the account is written with default status success
- **THEN** the account SHALL include details `Processed 3 of 5 items`
- **AND** SHALL include the operation output attribute outcome

#### Scenario: Success persist without details

- **GIVEN** a handler calls `ctx.persist('wf-run-011', { outcome: 'done' })` without details
- **WHEN** the account is written
- **THEN** the account SHALL have status success
- **AND** SHALL NOT require attribute details to be present on the written account unless the handler supplied it

#### Scenario: Details truncated at STRING limit

- **GIVEN** a failure message or handler-supplied details string longer than 256 characters
- **WHEN** the framework writes the account
- **THEN** it SHALL store details truncated to 256 characters
- **AND** SHALL log a truncation warning

---

## MODIFIED Requirements

### Requirement: Base account schema on result source create

When the framework auto-provisions a new DelimitedFile result source, it SHALL apply the **base account schema** immediately after source creation. The base schema SHALL include core framework attributes (`id`, `status`, `date`, `details`) plus the union of all registered custom operation output fields (excluding reserved framework keys), with typed inference matching templates generator and persist-time reconciliation rules.

If an account schema already exists on the newly created source (for example from ISC schema discovery), the framework SHALL align that schema to the base schema by adding missing attributes and correcting schema metadata (`identityAttribute`, `displayAttribute`, `nativeObjectType`, `name`) when absent or incorrect. The framework SHALL NOT remove existing attributes. Type and isMulti conflicts SHALL follow the same warn-only policy as persist-time schema reconciliation.

#### Scenario: New source receives full base schema

- **GIVEN** no ISC source exists with the configured sourceName
- **AND** registered operations declare output fields `summary` and `violationId`
- **WHEN** a custom operation invocation auto-creates the result source
- **THEN** the framework SHALL create or align the account schema to include `id`, `status`, `date`, `details`, `summary`, and `violationId`
- **AND** SHALL set `identityAttribute` to `id`

#### Scenario: ISC-discovered schema replaced with base schema

- **GIVEN** source create completes and ISC has already materialized an account schema with only discovered CSV columns
- **WHEN** the framework applies the base account schema
- **THEN** the framework SHALL patch the existing account schema to add all base schema attributes including `details`
- **AND** SHALL NOT fail with a duplicate schema create error

#### Scenario: Base schema excludes reserved framework keys

- **GIVEN** registered operation output includes field `sourceId`
- **WHEN** base schema is applied on source create
- **THEN** the account schema SHALL NOT include attribute `sourceId`

#### Scenario: Existing result source unchanged

- **GIVEN** an ISC result source with the configured sourceName already exists
- **WHEN** a custom operation is invoked
- **THEN** the framework SHALL resolve the existing source ID
- **AND** SHALL NOT re-apply the base account schema

---

### Requirement: Failed operation responses for custom operations

The framework SHALL catch every failure escaping a `customOperation`-wrapped handler, normalize it via `toConnectorError` (plain `Error`, axios rejections, `PersistVerificationError`, and existing `ConnectorError`), and send `{ status: 'failed', error: <message> }` on the command response when the handler has not already sent a response. The invocation SHALL resolve without throwing so local spcx and workflow HTTP invokes return success transport status with a terminal failed payload instead of HTTP 500 retries. For every terminal failed response, the framework SHALL also upsert a result source account for the invoke `requestId` with `status` failed and `details` set to the same normalized message as described in **Automatic failed account persist on terminal failure**.

#### Scenario: Handler throws plain Error

- **GIVEN** a custom operation handler that throws `new Error('operation failed')`
- **WHEN** ISC invokes the custom command via `customOperation`
- **THEN** the invocation SHALL resolve without throwing
- **AND** the response SHALL include status failed
- **AND** the error field SHALL include the original failure message
- **AND** a result account SHALL exist for requestId with status failed and matching details

#### Scenario: Initialization failure before handler runs

- **GIVEN** test mode is active with provided config and ISC status check rejects with a plain SDK error
- **WHEN** `customOperation` initializes the request context
- **THEN** the invocation SHALL resolve without throwing
- **AND** the response SHALL include status failed with the normalized error message
- **AND** a failed result account with details SHALL be written when persist is available

#### Scenario: Persist verification failure

- **GIVEN** a handler calls `ctx.persist` and account read-back verification fails after bounded retries
- **WHEN** the persist helper throws `PersistVerificationError`
- **THEN** the invocation SHALL resolve without throwing
- **AND** the response SHALL include status failed describing the verification failure
- **AND** a failed result account with details SHALL be written

#### Scenario: Existing ConnectorError message preserved

- **GIVEN** a handler or framework helper throws `new ConnectorError('missing field')`
- **WHEN** the error is handled by `customOperation`
- **THEN** the failed response error field SHALL include missing field without double-wrapping prefixes beyond the optional command context
- **AND** account details SHALL include the same normalized message

#### Scenario: HTTP 404 maps to NotFound type

- **GIVEN** an ISC client call fails with HTTP status 404
- **WHEN** the error is normalized by the framework
- **THEN** the resulting `ConnectorError` SHALL have type `notFound` before its message is placed on the failed response and account details

---

### Requirement: Test mode persistence console logging

When test mode is active, the framework SHALL log each inhibited persist and verifyPersisted operation to console with a test-mode prefix including identity, status, and formatted attributes.

#### Scenario: Inhibited failed persist logged with details

- **GIVEN** test mode is active
- **WHEN** a terminal failure triggers automatic failed account persist
- **THEN** console output SHALL include a test-mode inhibited persist line for the requestId
- **AND** SHALL include status failed and details in the logged attributes

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
