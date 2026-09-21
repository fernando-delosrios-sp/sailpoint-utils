## ADDED Requirements

### Requirement: Operation-declared result identity

The framework SHALL accept an optional `resultIdentity` builder in the `customOperation` options, a pure function from the invoke `requestId` to the result-source identity that operation writes. The framework SHALL resolve it once while constructing the request context, before the handler body runs, and SHALL expose the resolved value as `ctx.resultIdentity`. When an operation does not declare `resultIdentity`, `ctx.resultIdentity` SHALL equal the invoke `requestId`. The framework SHALL NOT apply any prefix or transformation of its own.

#### Scenario: Declared builder resolves the result identity

- **GIVEN** an operation declares `resultIdentity: (requestId) => \`my-op:${requestId}\``
- **AND** invoke input contains requestId `wf-run-101`
- **WHEN** the framework constructs the request context
- **THEN** `ctx.resultIdentity` SHALL be `my-op:wf-run-101`

#### Scenario: Omitted builder defaults to the request id

- **GIVEN** an operation declares no `resultIdentity`
- **AND** invoke input contains requestId `wf-run-102`
- **WHEN** the framework constructs the request context
- **THEN** `ctx.resultIdentity` SHALL be `wf-run-102`

#### Scenario: Result identity is available before the handler runs

- **GIVEN** an operation declares a `resultIdentity` builder
- **WHEN** request context initialization completes but the handler body has not executed
- **THEN** the resolved result identity SHALL already be available to the framework failure path

---

## MODIFIED Requirements

### Requirement: Automatic failed account persist on terminal failure

The framework SHALL upsert a result source account for the resolved result identity (`ctx.resultIdentity`, which defaults to the invoke `requestId`) with `status` failed, `details` set to the normalized failure message, and `operationName` set from the invocation command when known whenever a `customOperation`-wrapped invocation terminates with `{ status: 'failed', error }` on the command response and a request context with persist was initialized. This SHALL apply to handler throws normalized by `toConnectorError`, initialization failures before the handler completes, persist verification failures, and handler-initiated `res.send({ status: 'failed', error })` payloads. The framework SHALL perform this persist before or together with sending the failed invoke response. If failure persist itself errors, the framework SHALL log the error and SHALL still send the failed invoke response without throwing.

#### Scenario: Handler throw persists failed account

- **GIVEN** a custom operation handler throws `new Error('operation failed')`
- **AND** invoke input contains requestId `wf-run-001`
- **AND** the invocation commandType is `custom:example`
- **AND** the operation declares no `resultIdentity`
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

#### Scenario: Declared result identity receives the failed account

- **GIVEN** an operation declares `resultIdentity: (requestId) => \`my-op:${requestId}\``
- **AND** invoke input contains requestId `wf-run-005`
- **WHEN** the handler throws and `customOperation` handles the terminal failure
- **THEN** the framework SHALL upsert a failed account with identity `my-op:wf-run-005`
- **AND** SHALL NOT upsert a failed account with identity `wf-run-005`

#### Scenario: Declared result identity covers initialization failures

- **GIVEN** an operation declares `resultIdentity: (requestId) => \`my-op:${requestId}\``
- **AND** invoke input contains requestId `wf-run-006`
- **WHEN** `customOperation` fails before the handler body executes
- **THEN** the framework SHALL upsert the failed account with identity `my-op:wf-run-006` when persist is available
