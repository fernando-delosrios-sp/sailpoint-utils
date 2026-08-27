## MODIFIED Requirements

### Requirement: Result persistence helper

The framework SHALL provide persist(id, attributes?, status?, options?) on a RequestContext typed to the operation output signature. Before writing the account, the framework SHALL reconcile the result source schema for the current operation. The attributes parameter SHALL accept Partial of the operation output type. The framework SHALL always set id, sourceId, date, and status; author-supplied keys matching those names SHALL be ignored. The framework SHALL format attribute values for ISC storage using typed inference: strings booleans numbers bigint and Date stored as native values matching their ISC types, objects and unknown values JSON-serialized to STRING, arrays stored per element type rules with isMulti true on schema. The options parameter SHALL accept verify boolean where verify defaults to true. When no account exists for the identity on the result source, the framework SHALL create the account via createAccountV1. When an account already exists for the identity, the framework SHALL update the account via putAccountV1 using the ISC account id from list lookup. When verify is true, the framework SHALL read the account back and verify persisted attributes match written values with type-aware comparison before returning control. When verify is false, the framework SHALL skip inline read-back but SHALL record written attributes for later batch verification.

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
- **THEN** the framework SHALL update the account via putAccountV1 without error
- **AND** the framework SHALL NOT invoke createAccountV1
- **AND** the framework SHALL verify read-back outcome is updated before resolving

#### Scenario: Persist serializes array and object values

- **GIVEN** a request context typed to an output with name string and emails string array
- **WHEN** ctx.persist('req-001', { name: 'Fernando', emails: ['dfas', 'fasdfas'] }) is called
- **THEN** the framework SHALL store name as Fernando and emails as the string array
- **AND** the framework SHALL verify read-back name and emails match before resolving

#### Scenario: Persist ignores reserved framework keys in attributes

- **GIVEN** a request context typed to an output with outcome string
- **WHEN** ctx.persist('req-001', { id: 'override', status: 'override', outcome: 'ok' }) is called
- **THEN** the framework SHALL set id and status from framework logic
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
