## MODIFIED Requirements

### Requirement: Access model scan summary on invoke response

The access-model-sod-remediation operation SHALL return scan rollup counters on the successful command response via `ctx.res.send` as the operation response envelope `summary`. The handler SHALL NOT persist rollup counters on result-source identity `requestId`. The scan-summary counters SHALL be declared under `OperationSignature['response']` and SHALL NOT be declared in `OperationSignature['output']`; consequently they SHALL NOT appear as attributes on the result-source account schema. Only persisted child attributes SHALL be declared in `output`.

#### Scenario: Successful scan returns summary on res.send

- **GIVEN** a scan evaluates 50 access items and finds 3 violations creating 3 forms (2 skipped by idempotency)
- **WHEN** the handler completes successfully
- **THEN** `ctx.res.send` SHALL be called with `status: 'success'`
- **AND** the payload SHALL include `access-model-sod-remediation:access-items-scanned` equal to 50
- **AND** `access-model-sod-remediation:violations-found` equal to 3
- **AND** `access-model-sod-remediation:forms-skipped` equal to 2
- **AND** the handler SHALL NOT call `ctx.persist` with identity `requestId` for rollup counters

#### Scenario: Zero violations summary only

- **GIVEN** a scan evaluates 10 access items and finds no violations
- **WHEN** the handler completes successfully
- **THEN** `ctx.res.send` SHALL include `access-model-sod-remediation:access-items-scanned` equal to 10
- **AND** `access-model-sod-remediation:violations-found` equal to 0
- **AND** SHALL NOT persist any result-source account on identity `requestId`

#### Scenario: Optional failure counter on res.send

- **GIVEN** a scan creates forms where at least one child persist fails
- **WHEN** the handler completes successfully
- **THEN** `ctx.res.send` SHALL include `access-model-sod-remediation:forms-persist-failed` equal to the failure count
- **AND** SHALL omit `access-model-sod-remediation:forms-persist-failed` when the count is zero

#### Scenario: Scan-summary counters excluded from output and account schema

- **GIVEN** the operation declares scan-summary counters `access-items-scanned`, `violations-found`, `forms-skipped`, `forms-launch-failed`, and `forms-persist-failed`
- **WHEN** its `OperationSignature` is authored and codegen derives the account schema
- **THEN** these counters SHALL be declared under `response`
- **AND** SHALL NOT be declared under `output`
- **AND** SHALL NOT appear as attributes on the result-source account schema
- **AND** the persist-output guard SHALL pass for the operation
