## ADDED Requirements

### Requirement: Operation response envelope

The framework SHALL provide a typed operation response envelope for the `ctx.res.send` payload that is distinct from the persisted-attribute `output`. The envelope SHALL carry `name` (the operation/command name), `status`, `responses` (the native identities persisted during the invoke), and `summary` (per-operation response detail typed from an optional `OperationSignature['response']`). The framework SHALL populate `name`, `status`, and `responses`; the handler SHALL supply only `summary`. Response envelope fields SHALL NOT be propagated to the result-source account schema.

#### Scenario: Handler returns response via ctx.respond

- **GIVEN** an operation declares `response` summary fields on its `OperationSignature` interface
- **WHEN** the handler calls `ctx.respond(summary)` after persisting accounts
- **THEN** the framework SHALL call `ctx.res.send` with an envelope containing `name`, `status`, `responses`, and the supplied `summary`
- **AND** `summary` SHALL be typed as `OperationSignature['response']`

#### Scenario: responses lists persisted native ids

- **GIVEN** a handler persists accounts with native identities `req:child-a` and `req:child-b` during one invoke
- **WHEN** the handler calls `ctx.respond(summary)`
- **THEN** the envelope `responses` SHALL contain `req:child-a` and `req:child-b`
- **AND** SHALL be derived from the persist write registry, not from a handler-supplied list

#### Scenario: Response summary excluded from account schema

- **GIVEN** an operation declares response summary field `items-scanned` and persisted output field `form-url`
- **WHEN** codegen derives the account schema
- **THEN** the account schema SHALL include `form-url`
- **AND** SHALL NOT include `items-scanned`

#### Scenario: Default status

- **GIVEN** a handler calls `ctx.respond(summary)` without an explicit status
- **WHEN** the framework builds the envelope
- **THEN** `status` SHALL default to `success`

---

## MODIFIED Requirements

### Requirement: Operation signature

Each custom operation SHALL declare an OperationSignature interface with input and output fields using plain TypeScript types, and MAY declare an optional `response` field. The `output` field SHALL contain only attributes the operation persists via `ctx.persist` and SHALL be the sole source of the result-source account schema; it SHALL NOT contain `ctx.res.send` response or summary content. The optional `response` field SHALL type the operation response envelope `summary`. The interface MAY optionally declare `command?: string` as a string literal for build-time auto-registration. The framework SHALL provide customOperation to register the handler; input and ctx.persist attribute types SHALL be inferred from that interface at compile time.

#### Scenario: Operation declares command for auto-registration

- **GIVEN** an operation defines `interface ExampleOperation extends OperationSignature` with `command: 'custom:example'`, input, and output fields
- **WHEN** codegen runs
- **THEN** the operation SHALL be included in the generated auto-registry without manual index.ts registration

#### Scenario: Operation declares combined input and output signature

- **GIVEN** an operation defines interface ExampleOperation extending OperationSignature with input message optional string and output summary string and optional step string
- **WHEN** the operation is registered via customOperation with a handler typed to ExampleOperation
- **THEN** the handler input parameter SHALL be typed as ExampleOperation input
- **AND** ctx.persist SHALL accept Partial of ExampleOperation output

#### Scenario: Output declares persisted attributes only

- **GIVEN** an operation persists child accounts with attribute `form-url` and returns rollup counter `items-scanned` via the response envelope
- **WHEN** its OperationSignature is authored
- **THEN** `output` SHALL declare `form-url`
- **AND** `output` SHALL NOT declare `items-scanned`
- **AND** `items-scanned` SHALL be declared under `response`
