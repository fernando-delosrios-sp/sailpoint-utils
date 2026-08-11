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

The project documentation SHALL describe persist inhibition via config testMode. The documentation SHALL state that ISC is skipped only when no invocation config is provided in a local invoke payload. When config is provided, the documentation SHALL state that apiUrl token and sourceName are required and read-only ISC checks run, failing on missing or invalid credentials.

#### Scenario: Persist inhibition documented in README

- **GIVEN** a developer reads the project README
- **WHEN** they look for local invoke guidance
- **THEN** the documentation SHALL explain testMode and SPCX_TEST_MODE as persist inhibition
- **AND** SHALL describe offline invoke versus connected dry-run behavior
- **AND** SHALL NOT describe token absence alone as the offline trigger
- **AND** SHALL NOT use fixture or test operation as the primary concept name for local invokes

### Requirement: Invoke payload documentation

The project documentation SHALL describe offline invoke payloads without a config section and connected dry-run payloads with full config including connection fields. Local invoke payload examples SHALL use type config and input top-level fields matching spcx invoke shape. Workflow invoke payload examples SHALL additionally include connectorRef and tag and SHALL use ISC workflow template variables for connectorRef and config connection fields rather than hardcoded tenant or connector identifiers.

#### Scenario: Payload format documented

- **GIVEN** a developer reads the project README
- **WHEN** they look for invoke payload file structure
- **THEN** the documentation SHALL show an offline example without a config object using type and input
- **AND** SHALL show a config-present example with apiUrl token sourceName and testMode
- **AND** SHALL reference npm run call:op as the script used to run payloads
- **AND** SHALL place example payloads under payloads/

#### Scenario: Workflow invoke payload shape documented

- **GIVEN** a developer reads the project README or payloads directory
- **WHEN** they look for workflow-ready invoke payload examples
- **THEN** the documentation or example files SHALL show connectorRef tag type input and config top-level fields
- **AND** connectorRef SHALL use an ISC workflow variable such as `{{$.configuration.saaSCustomOperationsConnectorID}}`
- **AND** config apiUrl token and sourceName SHALL use ISC workflow variables rather than hardcoded tenant values
- **AND** tag SHALL be the literal string `latest`

### Requirement: Local debug invoke envelope documentation

The project documentation SHALL describe the spcx local debug invoke POST body shape including type config and input fields. The documentation SHALL note that default incoming request logging prints the resolved envelope to stdout during npm run debug.

#### Scenario: spcx invoke shape documented

- **GIVEN** a developer reading the Development section of README
- **WHEN** they need to invoke the connector locally via spcx
- **THEN** the documentation SHALL show a JSON example with type config and input
- **AND** SHALL explain that config is passed as a top-level field separate from input

#### Scenario: Request logging behavior documented

- **GIVEN** a developer running npm run debug
- **WHEN** they read the Development section
- **THEN** the documentation SHALL describe default incoming request logging
- **AND** SHALL note that config.token is redacted in log output

### Requirement: Per-operation documentation pointers

The project root README SHALL state that each custom operation documents its invoke contract and workflow integration in `src/operations/<slug>/README.md`. Operation-specific invoke and workflow integration content SHALL NOT be duplicated in the root README when a per-operation README exists for that command.

#### Scenario: Root README points to operation docs

- **GIVEN** a developer reads the Extending the connector section of the project README
- **WHEN** they look for operation-specific invoke or workflow guidance
- **THEN** the documentation SHALL direct them to the co-located README in each operation subdirectory
- **AND** SHALL NOT require reading the root README for operation-specific workflow steps

#### Scenario: Operation README documents payloads

- **GIVEN** an operation has workflow-ready invoke examples under `payloads/` (e.g. `*-workflow.json`)
- **WHEN** a developer reads that operation's README
- **THEN** the README SHALL reference the relevant payload file paths for local and workflow invoke examples

