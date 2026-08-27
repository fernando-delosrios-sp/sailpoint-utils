## REMOVED Requirements

### Requirement: Declared commands

**Reason**: Requirement referenced std commands exclusively. Replaced by custom-command-only manifest requirements.

**Migration**: Update connector-spec.json to declare custom commands only.

### Requirement: Source configuration

**Reason**: Authentication credentials (apiUrl, token) are provided per custom operation invocation, not via static source config.

**Migration**: Remove or simplify sourceConfig; document standard input envelope instead.

### Requirement: Account schema

**Reason**: This connector is not an aggregation source. Account schema requirements move to dummy source documentation.

**Migration**: Remove firstName/lastName/email accountSchema from connector-spec.json. Document dummy source schema in README.

## ADDED Requirements

### Requirement: Custom commands manifest

The connector manifest SHALL declare custom commands only and SHALL NOT declare any std commands.

#### Scenario: Manifest contains custom commands only

- **GIVEN** the connector manifest is loaded by ISC
- **WHEN** the commands list is inspected
- **THEN** it SHALL contain only custom:* command entries and no std:* entries

### Requirement: Standard input envelope

Every custom operation SHALL document and accept a standard input envelope containing apiUrl, token, requestId, and sourceId.

#### Scenario: Standard fields parsed by framework

- **GIVEN** a custom operation input includes apiUrl, token, requestId, and sourceId
- **WHEN** withCustomOperation parses the input
- **THEN** all four fields SHALL be available on the request context or passed to the handler

### Requirement: Dummy source schema documentation

The project documentation SHALL describe the expected dummy source account schema required for result persistence.

#### Scenario: Dummy source schema documented

- **GIVEN** a developer reads the project README
- **WHEN** they look for dummy source prerequisites
- **THEN** the documentation SHALL specify identity attribute id and attributes id, date, status, param1 through param9
