<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Worker Group is a global Connection detail

Every Connection details field map SHALL include Worker Group (Connector) as an
operator-selected existing Connector. The Integration index MUST NOT repeat that
field on each row. Other Entro-owned labels (Environment, Display Name, Nickname)
SHALL appear only when curated on that row's `connectionFields` and SHALL be
collected as Operator inputs during Intro when they are non-secret. The Connect
log MUST persist the chosen names before Operation mode.

#### Scenario: Field map always names Worker Group

- **GIVEN** a locked Add New Account target
- **WHEN** a Connect log or skill writes Connection details
- **THEN** the field map MUST include Worker Group (Connector)
- **AND** its value MUST NOT be a secret stored in the Connect log

#### Scenario: Environment is not assumed

- **GIVEN** a target whose ingested form docs do not name Environment
- **WHEN** Connection details are taken from the index
- **THEN** the field map MUST NOT invent an Environment field
- **AND** it MUST still include Worker Group (Connector)

#### Scenario: Operator-chosen names are collected in Intro

- **GIVEN** a Lock whose Operator inputs include an Environment nickname
- **WHEN** the skill introduces the Integration
- **THEN** it MUST offer the catalog suggestion or a custom value
- **AND** the Connect log MUST persist the chosen name before Operation mode is offered

---

## MODIFIED Requirements

### Requirement: Entro fields are enumerated per Integration

For each supported Integration, the project SHALL list the connection details Entro
expects (field purpose, format, and where the value is obtained). Vendor-specific
fields SHALL come from that target's `connectionFields` in the Integration index
(`name`, `secret`, `obtainedHow`). Worker Group (Connector) SHALL be included by
the global rule. Operator-chosen non-secret values SHALL come from Operator inputs
bound to those fields. Secret fields SHALL be named with `secret` true and MUST NOT
persist values. Field maps MUST NOT require opening ingested documentation pages.

#### Scenario: Operator is ready to fill Entro

- **GIVEN** integration-prep for an Integration is complete
- **WHEN** the operator opens Entro's connection form for that Integration
- **THEN** they MUST have a field-by-field mapping from Entro's form to obtained values, including which values are secrets they must supply at runtime
- **AND** that mapping MUST be the global Worker Group field plus the row's `connectionFields`

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
