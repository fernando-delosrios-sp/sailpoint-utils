## ADDED Requirements

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
