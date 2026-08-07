## ADDED Requirements

### Requirement: Operation fixture envelope

The operation test runner SHALL accept a JSON fixture file containing `command` string, `config` object, and `input` object matching the ISC custom operation invoke shape.

#### Scenario: Valid fixture loads command and payload

- **GIVEN** a fixture file with command `custom:example`, config containing apiUrl token sourceName and testMode true, and input containing requestId and operation fields
- **WHEN** the operation test runner executes the fixture
- **THEN** the runner SHALL invoke the registered handler for that command with the provided config and input

#### Scenario: Missing command rejected

- **GIVEN** a fixture file without a command field
- **WHEN** the operation test runner executes the fixture
- **THEN** the runner SHALL exit with a non-zero status and an error message indicating command is required

### Requirement: Fixture runner captures res.send output

The operation test runner SHALL capture the handler response sent via ctx.res.send and print it to stdout as formatted JSON.

#### Scenario: res.send payload printed on success

- **GIVEN** a handler that calls ctx.res.send with an object payload
- **WHEN** the operation test runner completes execution
- **THEN** the runner SHALL print the send payload to stdout
- **AND** the runner SHALL exit with status code 0

### Requirement: npm script entry point

The project SHALL provide an npm script that runs the operation test runner against a fixture file path argument.

#### Scenario: test operation script documented

- **GIVEN** the project package.json scripts section
- **WHEN** a developer runs the test operation npm script with a fixture path after build
- **THEN** the script SHALL execute the fixture runner against that path
