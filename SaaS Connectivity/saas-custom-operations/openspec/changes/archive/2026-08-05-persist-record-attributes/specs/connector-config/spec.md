## MODIFIED Requirements

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
