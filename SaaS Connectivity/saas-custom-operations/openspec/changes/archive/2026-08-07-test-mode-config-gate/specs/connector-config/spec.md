## MODIFIED Requirements

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
