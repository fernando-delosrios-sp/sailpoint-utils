## MODIFIED Requirements

### Requirement: Base account schema on result source create

When the framework auto-provisions a new DelimitedFile result source, it SHALL apply the **base account schema** immediately after source creation. The base schema SHALL include core framework attributes (`id`, `status`, `date`, `details`) plus the **output fields of the invoking custom operation** (from `operationSchema.outputFields` on the current invocation), excluding reserved framework keys, with typed inference matching templates generator and persist-time reconciliation rules.

If an account schema already exists on the newly created source (for example from ISC schema discovery), the framework SHALL align that schema to the base schema by adding missing attributes and correcting schema metadata (`identityAttribute`, `displayAttribute`, `nativeObjectType`, `name`) when absent or incorrect. The framework SHALL NOT remove existing attributes. Type and isMulti conflicts SHALL follow the same warn-only policy as persist-time schema reconciliation.

When `operationSchema` is unavailable at source create, the framework SHALL apply core framework attributes only and SHALL rely on persist-time reconciliation to add operation output fields on first `ctx.persist`.

#### Scenario: New source receives full base schema

- **GIVEN** no ISC source exists with the configured sourceName
- **AND** the invoking operation declares output fields `summary` and `step`
- **AND** other registered operations declare output field `violationId`
- **WHEN** a custom operation invocation auto-creates the result source
- **THEN** the framework SHALL create or align the account schema to include `id`, `status`, `date`, `details`, `summary`, and `step`
- **AND** the account schema SHALL NOT include `violationId` from other registered operations
- **AND** SHALL set `identityAttribute` to `id`

#### Scenario: ISC-discovered schema replaced with base schema

- **GIVEN** source create completes and ISC has already materialized an account schema with only discovered CSV columns
- **WHEN** the framework applies the base account schema for the invoking operation
- **THEN** the framework SHALL patch the existing account schema to add core attributes and the invoking operation's output fields including `details`
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
- **THEN** the applied base account schema SHALL include only `id`, `status`, `date`, and `details`

---

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
- **WHEN** the templates generator builds reference account schema from the union of registered operation outputs
- **THEN** attribute `details` SHALL come only from framework core attributes
- **AND** SHALL NOT be duplicated from operation output field definitions
