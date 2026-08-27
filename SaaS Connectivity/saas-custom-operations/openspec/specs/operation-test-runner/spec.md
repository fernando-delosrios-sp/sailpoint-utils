# operation-test-runner Specification

## Purpose
Local invoke runner for custom operations via JSON invoke payloads (`npm run call:op`).
## Requirements
### Requirement: Invoke payload envelope

The local invoke runner SHALL accept a JSON payload file containing `type` string and `input` object. The `config` object SHALL be optional; when omitted the runner SHALL invoke the handler without context.config for offline persist inhibition.

#### Scenario: Valid payload loads type and input

- **GIVEN** a payload file with type custom:example and input containing requestId and operation fields
- **WHEN** the local invoke runner executes the payload with SPCX_TEST_MODE set
- **THEN** the runner SHALL invoke the registered handler without supplying context.config

#### Scenario: Valid payload with config loads connection fields

- **GIVEN** a payload file with type config containing apiUrl token sourceName and testMode true and input containing requestId
- **WHEN** the local invoke runner executes the payload
- **THEN** the runner SHALL invoke the handler with context.config set to the payload config

#### Scenario: Missing type rejected

- **GIVEN** a payload file without a type field
- **WHEN** the local invoke runner executes the payload
- **THEN** the runner SHALL exit with a non-zero status and an error message indicating type is required

### Requirement: Local invoke runner captures res.send output

The local invoke runner SHALL capture the handler response sent via ctx.res.send and print it to stdout as formatted JSON.

#### Scenario: res.send payload printed on success

- **GIVEN** a handler that calls ctx.res.send with an object payload
- **WHEN** the local invoke runner completes execution
- **THEN** the runner SHALL print the send payload to stdout
- **AND** the runner SHALL exit with status code 0

### Requirement: npm script entry point

The project SHALL provide an npm script named `call:op` that runs the local invoke runner against a payload file path argument.

#### Scenario: call op script documented

- **GIVEN** the project package.json scripts section
- **WHEN** a developer runs the call op npm script with a payload path after build
- **THEN** the script SHALL execute the local invoke runner against that path

### Requirement: Local invoke exit code on failed command output

The local operation runner (`npm run call:op`) SHALL exit with code 1 when the handler response payload has `status: 'failed'`, and exit 0 otherwise. The runner SHALL NOT treat a failed status payload as an uncaught exception when the handler returned `{ status: 'failed', error }` via `res.send`.

#### Scenario: Failed status payload exits 1

- **GIVEN** a payload invokes an operation whose handler returns `{ status: 'failed', error: 'boom' }`
- **WHEN** `runPayloadFromPath` completes
- **THEN** the process exit code SHALL be 1
- **AND** stderr SHALL include the error message

#### Scenario: Success status payload exits 0

- **GIVEN** a payload invokes an operation that completes without failed status
- **WHEN** `runPayloadFromPath` completes
- **THEN** the process exit code SHALL be 0

#### Scenario: Failed invoke summary includes inhibited failed persist

- **GIVEN** test mode inhibits ISC writes and an operation terminates with status failed
- **WHEN** `runPayloadFromPath` runs with config-less or testMode payload
- **THEN** the payload output summary or test-mode inhibited persist log SHALL include the failed account identity, status failed, details attribute, and operationName attribute when automatic failure persist ran

