# custom-operation-framework Delta

## ADDED Requirements

### Requirement: Base account schema on result source create

When the framework auto-provisions a new DelimitedFile result source, it SHALL apply the **base account schema** immediately after source creation. The base schema SHALL include core framework attributes (`id`, `status`, `date`) plus the union of all registered custom operation output fields (excluding reserved framework keys), with typed inference matching templates generator and persist-time reconciliation rules.

If an account schema already exists on the newly created source (for example from ISC schema discovery), the framework SHALL align that schema to the base schema by adding missing attributes and correcting schema metadata (`identityAttribute`, `displayAttribute`, `nativeObjectType`, `name`) when absent or incorrect. The framework SHALL NOT remove existing attributes. Type and isMulti conflicts SHALL follow the same warn-only policy as persist-time schema reconciliation.

#### Scenario: New source receives full base schema

- **GIVEN** no ISC source exists with the configured sourceName
- **AND** registered operations declare output fields `summary` and `violationId`
- **WHEN** a custom operation invocation auto-creates the result source
- **THEN** the framework SHALL create or align the account schema to include `id`, `status`, `date`, `summary`, and `violationId`
- **AND** SHALL set `identityAttribute` to `id`

#### Scenario: ISC-discovered schema replaced with base schema

- **GIVEN** source create completes and ISC has already materialized an account schema with only discovered CSV columns
- **WHEN** the framework applies the base account schema
- **THEN** the framework SHALL patch the existing account schema to add all base schema attributes
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

## MODIFIED Requirements

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
- **AND** the framework SHALL apply the base account schema on the new source
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

- **GIVEN** a newly created result source with base schema applied
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
