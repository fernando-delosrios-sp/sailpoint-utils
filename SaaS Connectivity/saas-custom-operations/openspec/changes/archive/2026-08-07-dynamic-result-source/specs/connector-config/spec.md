## MODIFIED Requirements

### Requirement: Standard input envelope

Every custom operation SHALL document and accept a standard input envelope containing apiUrl, token, requestId, and sourceName. The framework SHALL resolve sourceName to a source ID at runtime.

#### Scenario: Standard fields parsed by framework

- **GIVEN** a custom operation input includes apiUrl, token, requestId, and sourceName
- **WHEN** withCustomOperation parses the input
- **THEN** all four fields SHALL be available on the request context or passed to the handler
- **AND** the framework SHALL resolve sourceName to sourceId before the handler executes

#### Scenario: Missing sourceName rejected

- **GIVEN** connector config omits sourceName or it is empty
- **WHEN** a custom operation is invoked
- **THEN** the framework SHALL reject with a ConnectorError indicating the missing field

## REMOVED Requirements

### Requirement: Dummy source schema documentation

**Reason:** The connector auto-provisions the result source and reconciles schema at persist time; manual dummy-source schema setup is no longer a prerequisite.

**Migration:** README SHALL document sourceName configuration and token scope requirements instead of manual account-schema application steps.

## ADDED Requirements

### Requirement: Result source name configuration

The connector manifest SHALL declare sourceName as a required connection config field and SHALL NOT declare sourceId.

#### Scenario: Manifest uses sourceName

- **GIVEN** the connector manifest sourceConfig is loaded
- **WHEN** the Connection section is inspected
- **THEN** it SHALL include a required sourceName text field
- **AND** it SHALL NOT include a sourceId field

### Requirement: Auto-provisioning documentation

The project documentation SHALL describe automatic result source creation and token permission prerequisites.

#### Scenario: Auto-provision prerequisites documented

- **GIVEN** a developer reads the project README
- **WHEN** they look for result source setup
- **THEN** the documentation SHALL explain that sourceName identifies a DelimitedFile source created automatically if missing
- **AND** the documentation SHALL list required token scopes for source and schema management
- **AND** the documentation SHALL state that account schema is reconciled at persist time per operation
