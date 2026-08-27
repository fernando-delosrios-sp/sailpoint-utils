## MODIFIED Requirements

### Requirement: Operation fixture envelope

The operation test runner SHALL accept a JSON fixture file containing `command` string and `input` object. The `config` object SHALL be optional; when omitted the runner SHALL invoke the handler without context.config for offline test mode.

#### Scenario: Valid fixture loads command and payload

- **GIVEN** a fixture file with command custom:example and input containing requestId and operation fields
- **WHEN** the operation test runner executes the fixture with SPCX_TEST_MODE set
- **THEN** the runner SHALL invoke the registered handler without supplying context.config

#### Scenario: Valid fixture with config loads connection fields

- **GIVEN** a fixture file with command config containing apiUrl token sourceName and testMode true and input containing requestId
- **WHEN** the operation test runner executes the fixture
- **THEN** the runner SHALL invoke the handler with context.config set to the fixture config

#### Scenario: Missing command rejected

- **GIVEN** a fixture file without a command field
- **WHEN** the operation test runner executes the fixture
- **THEN** the runner SHALL exit with a non-zero status and an error message indicating command is required
