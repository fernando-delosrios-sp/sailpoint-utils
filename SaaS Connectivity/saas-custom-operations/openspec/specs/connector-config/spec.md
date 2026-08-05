## Purpose

ISC connector manifest configuration for custom-operation-only connectors, covering declared custom commands and standard input envelope documentation.
## Requirements
### Requirement: Custom commands manifest

The connector manifest SHALL declare custom commands only and SHALL NOT declare any std commands.

#### Scenario: Manifest contains custom commands only

- **GIVEN** the connector manifest is loaded by ISC
- **WHEN** the commands list is inspected
- **THEN** it SHALL contain only custom:* command entries and no std:* entries

### Requirement: Standard input envelope

Every custom operation SHALL document and accept a standard input envelope containing apiUrl, token, requestId, and sourceId.

#### Scenario: Standard fields parsed by framework

- **GIVEN** a custom operation input includes apiUrl, token, requestId, and sourceId
- **WHEN** withCustomOperation parses the input
- **THEN** all four fields SHALL be available on the request context or passed to the handler

### Requirement: Dummy source schema documentation

The project documentation SHALL describe the expected dummy source account schema required for result persistence.

#### Scenario: Dummy source schema documented

- **GIVEN** a developer reads the project README
- **WHEN** they look for dummy source prerequisites
- **THEN** the documentation SHALL specify framework-managed attributes id (identity), date, and status
- **AND** the documentation SHALL explain that operations declare output fields via OperationSignature and persist named attributes via ctx.persist

#### Scenario: Operation template demonstrates operation signature

- **GIVEN** a developer copies src/operations/_template.ts
- **WHEN** they implement a new custom operation
- **THEN** the template SHALL show defining an OperationSignature interface with input and output fields and registering the handler via customOperation

