## ADDED Requirements

### Requirement: Test mode configuration documentation

The project documentation SHALL describe optional config testMode and environment variable SPCX_TEST_MODE for local dry-run execution without ISC persistence. The documentation SHALL explain that providing a valid access token enables read-only ISC status checks while omitting the token skips all ISC calls.

#### Scenario: Test mode documented in README

- **GIVEN** a developer reads the project README
- **WHEN** they look for local operation testing guidance
- **THEN** the documentation SHALL explain testMode and SPCX_TEST_MODE
- **AND** SHALL state that test mode inhibits ISC persistence and is intended for local development
- **AND** SHALL describe token-present vs token-absent behavior

### Requirement: Fixture envelope documentation

The project documentation SHALL describe the JSON fixture format with command config and input fields for the operation test runner, including examples with and without access token.

#### Scenario: Fixture format documented

- **GIVEN** a developer reads the project README
- **WHEN** they look for fixture file structure
- **THEN** the documentation SHALL show an example fixture with command config and input
- **AND** SHALL show a minimal offline fixture without token
- **AND** SHALL reference the npm script used to run fixtures
