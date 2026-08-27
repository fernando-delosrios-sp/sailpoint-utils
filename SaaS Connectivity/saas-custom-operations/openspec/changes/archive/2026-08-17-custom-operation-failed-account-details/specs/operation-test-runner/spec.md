## ADDED Requirements

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
- **THEN** the payload output summary or test-mode inhibited persist log SHALL include the failed account identity, status failed, and details attribute when automatic failure persist ran
