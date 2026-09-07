# connection-details

## Purpose

Which values Entro needs to complete an Integration, and how the operator obtains
them. Secret values themselves are never stored in this project.
## Requirements
### Requirement: Connection detail fields are enumerated

For each supported Integration, the project SHALL list the connection details Entro
expects (field purpose, format, and where the value is obtained). The field map MUST
contain shared tile `connectionFields`, the locked Integration path's
`connectionFields`, and Worker Group (Connector). It MUST NOT merge fields from
other Integration paths on the same tile. Fields owned by an Optional capability
MUST appear only when the operator enabled that capability during Prep.
Operator-chosen non-secret values SHALL come from Operator inputs bound to those
fields. Secret fields SHALL be named with `secret` true and MUST NOT persist values.
Field maps MUST NOT require opening ingested documentation pages.

#### Scenario: Applicable fields are enumerated

- **GIVEN** an Integration and path have been locked
- **WHEN** the Connection details field map is assembled
- **THEN** it MUST contain shared tile fields, locked-path fields, and Worker Group
- **AND** it MUST contain fields from an Optional capability only when that capability is enabled

### Requirement: Connection detail map is operator-ready

The project SHALL provide an operator-ready field map for the locked Integration
and path after Integration prep.

#### Scenario: Operator is ready to fill Entro

- **GIVEN** integration-prep for a locked Integration and path is complete
- **WHEN** the operator opens Entro's connection form for that Integration
- **THEN** they MUST have a field-by-field mapping from Entro's form to obtained values, including which values are secrets they must supply at runtime
- **AND** that mapping MUST be the global Worker Group field plus shared tile fields and the locked path's fields
- **AND** it MUST include enabled Optional capability fields only

### Requirement: Connection details bind to locked path

The Connection details field map MUST be the locked Integration path's
`connectionFields` plus shared tile fields and Worker Group (Connector). Fields
MUST NOT be merged from other paths on the same tile or from Optional
capabilities unless the operator enabled that capability during Prep.

#### Scenario: Path-specific credentials

- **GIVEN** a locked Google GCP path Console manual — Private Key Integration
- **WHEN** Connection details are written
- **THEN** the Private Key JSON field MUST appear
- **AND** Workload Identity Federation fields MUST NOT appear

### Requirement: Secrets are referenced, not stored

Connection-detail records SHALL name secret fields and how the user provides them
at connect time. They MUST NOT persist secret values in git, crawl output committed
as source of truth, Connect logs, or agent memory dumps.

#### Scenario: Credential appears in vendor docs as an example

- **GIVEN** ingested documentation shows a sample token or key
- **WHEN** connection-details are authored
- **THEN** the record MUST describe the field only and MUST NOT copy the sample secret into specs, skills, or committed artifacts

#### Scenario: Connect log leaves secrets blank

- **GIVEN** a `connectionFields` item with `secret` true
- **WHEN** a Connect log records Connection details
- **THEN** the log MUST name the field
- **AND** the log MUST leave the value blank

### Requirement: Worker Group is a global Connection detail

Every Connection details field map SHALL include Worker Group (Connector) as an
operator-selected existing Connector. The Integration index MUST NOT repeat that
field on each row. Other Entro-owned labels (Environment, Display Name, Nickname)
SHALL appear only when curated on the Integration tile or locked path's
`connectionFields` and SHALL be
collected as Operator inputs during Intro when they are non-secret. The Connect
log MUST persist the chosen names before Operation mode.

#### Scenario: Field map always names Worker Group

- **GIVEN** a locked Integration and implicit or explicit Integration path
- **WHEN** a Connect log or skill writes Connection details
- **THEN** the field map MUST include Worker Group (Connector)
- **AND** its value MUST NOT be a secret stored in the Connect log

#### Scenario: Environment is not assumed

- **GIVEN** a locked Integration path whose evidenced form does not name Environment
- **WHEN** Connection details are taken from the index
- **THEN** the field map MUST NOT invent an Environment field
- **AND** it MUST still include Worker Group (Connector)

#### Scenario: Operator-chosen names are collected in Intro

- **GIVEN** a locked Integration path whose Operator inputs include an Environment nickname
- **WHEN** the skill introduces the Integration
- **THEN** it MUST offer the catalog suggestion or a custom value
- **AND** the Connect log MUST persist the chosen name before Operation mode is offered

---

