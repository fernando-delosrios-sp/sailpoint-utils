# target-client/sources Specification

## Purpose

Generic ISC Sources API wrappers under `src/isc/sources/`. Callers supply payloads and interpret responses; this module SHALL NOT encode result-source provisioning policy, DelimitedFile defaults, operation output schema reconciliation, or persist orchestration.

## Requirements

### Requirement: Generic Sources API boundary

The isc sources module SHALL expose thin wrappers around `SourcesApi` methods. Functions SHALL accept caller-supplied request payloads and return SDK responses or parsed data. The module SHALL NOT hardcode DelimitedFile connector configuration, default account schema shapes, JWT-driven auto-provisioning flows, or operation output field reconciliation.

#### Scenario: Source lookup by filter

- **GIVEN** a configured `SourcesApi` and source name `{sourceName}`
- **WHEN** `findSourceByName` is invoked
- **THEN** the function SHALL call `listSourcesV1` with a name equality filter
- **AND** SHALL return the first matching source record or undefined

#### Scenario: Source create uses caller payload

- **GIVEN** a caller-supplied source create payload
- **WHEN** `createSource` is invoked
- **THEN** the function SHALL call `createSourceV1` with that payload
- **AND** SHALL return the created source id

#### Scenario: Account schema read

- **GIVEN** a valid source id
- **WHEN** `getAccountSchema` is invoked
- **THEN** the function SHALL call `getSourceSchemasV1`
- **AND** SHALL return the account schema entry when present

#### Scenario: Account schema create uses caller payload

- **GIVEN** a caller-supplied schema payload
- **WHEN** `createAccountSchema` is invoked
- **THEN** the function SHALL call `createSourceSchemaV1` with that payload

#### Scenario: Account schema patch

- **GIVEN** JSON Patch operations supplied by the caller
- **WHEN** `patchAccountSchema` is invoked with a non-empty patch list
- **THEN** the function SHALL call `updateSourceSchemaV1`

#### Scenario: Connectivity probe

- **WHEN** `verifyIscStatus` is invoked
- **THEN** the function SHALL perform a minimal `listSourcesV1` call to verify credentials
