## Purpose

ISC connector manifest configuration for custom-operation-only connectors, covering declared custom commands and standard input envelope documentation.
## Requirements
### Requirement: Custom commands manifest

The connector manifest SHALL declare custom commands only and SHALL NOT declare any std commands. The `commands` array SHALL be synchronized at build time from all discovered operations (auto-discovered and manually registered).

#### Scenario: Manifest contains custom commands only

- **GIVEN** the connector manifest is loaded by ISC
- **WHEN** the commands list is inspected
- **THEN** it SHALL contain only custom:* command entries and no std:* entries

#### Scenario: Manifest commands synced from discovery

- **GIVEN** auto-discovered operations declare `custom:example` and a manual operation is registered as `custom:legacy`
- **WHEN** codegen runs during prebuild
- **THEN** `connector-spec.json` commands SHALL equal the sorted union of all discovered command names
- **AND** other manifest keys such as sourceConfig SHALL be preserved unchanged

#### Scenario: Invalid command prefix fails build

- **GIVEN** an operation declares `command: 'std:example'` on its OperationSignature
- **WHEN** codegen runs
- **THEN** the build SHALL fail with a descriptive error

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

### Requirement: Test mode configuration documentation

The project documentation SHALL describe that test mode skips ISC only when no invocation config is provided. When config is provided, the documentation SHALL state that apiUrl token and sourceName are required and read-only ISC checks run, failing on missing or invalid credentials.

#### Scenario: Test mode documented in README

- **GIVEN** a developer reads the project README
- **WHEN** they look for local operation testing guidance
- **THEN** the documentation SHALL explain testMode and SPCX_TEST_MODE
- **AND** SHALL describe no-config offline behavior versus config-present read-only ISC behavior
- **AND** SHALL NOT describe token absence alone as the offline trigger

### Requirement: Fixture envelope documentation

The project documentation SHALL describe offline fixtures without a config section, activated via SPCX_TEST_MODE, and online dry-run fixtures with full config including connection fields.

#### Scenario: Fixture format documented

- **GIVEN** a developer reads the project README
- **WHEN** they look for fixture file structure
- **THEN** the documentation SHALL show an offline example without a config object
- **AND** SHALL show a config-present example with apiUrl token sourceName and testMode
- **AND** SHALL reference the npm script used to run fixtures

