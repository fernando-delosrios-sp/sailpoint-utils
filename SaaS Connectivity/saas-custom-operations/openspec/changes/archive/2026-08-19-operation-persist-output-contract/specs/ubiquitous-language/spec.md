## ADDED Requirements

### Requirement: Operation response term

The glossary SHALL define **operation response** as the typed payload a custom operation returns via `ctx.res.send`, an envelope comprising `name` (operation/command name), `status`, `responses` (the native identities persisted during the invoke), and `summary` (per-operation response detail typed from `OperationSignature['response']`). The operation response SHALL NOT be persisted and SHALL NOT contribute attributes to the result-source account schema.

#### Scenario: Operation response term

- **GIVEN** specs or code name the typed `ctx.res.send` payload of a custom operation
- **WHEN** normative text names that envelope
- **THEN** it SHALL use **operation response**
- **AND** SHALL distinguish it from the persisted **operation output** that feeds the account schema

#### Scenario: Operation response excluded from account schema

- **GIVEN** documentation describes what propagates to the result-source account schema
- **WHEN** the operation response is mentioned
- **THEN** it SHALL state that operation response fields are NOT account schema attributes

### Requirement: Response id list term

The glossary SHALL define **response id list** as the `responses: string[]` field on the operation response — the native identities written via `ctx.persist` during the invoke, enabling callers to correlate the response to result-source accounts.

#### Scenario: Response id list term

- **GIVEN** specs or code name the array of persisted identities on the operation response
- **WHEN** normative text names that field
- **THEN** it SHALL use **response id list** for the `responses` concept
- **AND** SHALL describe its values as native identities, not ISC account UUIDs

---

## MODIFIED Requirements

### Requirement: Access model scan summary term

The glossary SHALL define **scan summary** as the access-model-specific instance of the general **operation response** summary: the rollup counters returned on the successful `custom:access-model-sod-remediation` invoke response via `ctx.res.send`, comprising `access-model-sod-remediation:access-items-scanned`, `access-model-sod-remediation:violations-found`, and optional `access-model-sod-remediation:forms-skipped` and `access-model-sod-remediation:forms-persist-failed`. Optional `forms-skipped` SHALL count violations skipped because the child persist account already exists. The scan summary SHALL be delivered as the operation response `summary`, SHALL NOT be persisted as a result-source account on `requestId`, SHALL NOT be declared in `OperationSignature['output']`, and SHALL NOT appear as a result-source account schema attribute.

#### Scenario: Scan summary term

- **GIVEN** specs or code refer to rollup counts from an access-model scan invoke
- **WHEN** normative text names the delivery mechanism
- **THEN** it SHALL use **scan summary** for the operation response summary payload
- **AND** SHALL NOT describe rollup counters as a parent or summary result-source account on `requestId`

#### Scenario: Scan summary is an operation response summary

- **GIVEN** documentation relates scan summary to the general vocabulary
- **WHEN** the terms are compared
- **THEN** **scan summary** SHALL be described as the access-model instance of **operation response** summary
- **AND** SHALL NOT be declared in `OperationSignature['output']` nor appear on the account schema
