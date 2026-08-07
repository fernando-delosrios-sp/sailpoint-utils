## MODIFIED Requirements

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
