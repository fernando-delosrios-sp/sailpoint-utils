## MODIFIED Requirements

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

The project documentation SHALL describe offline invoke payloads without a config section and connected dry-run payloads with full config including connection fields. Payload examples SHALL use type config and input top-level fields matching spcx invoke shape.

#### Scenario: Payload format documented

- **GIVEN** a developer reads the project README
- **WHEN** they look for invoke payload file structure
- **THEN** the documentation SHALL show an offline example without a config object using type and input
- **AND** SHALL show a config-present example with apiUrl token sourceName and testMode
- **AND** SHALL reference npm run call:op as the script used to run payloads
- **AND** SHALL place example payloads under payloads/

## RENAMED Requirements

- FROM: `### Requirement: Fixture envelope documentation`
- TO: `### Requirement: Invoke payload documentation`
