## ADDED Requirements

### Requirement: Integration tile identity

The Integration catalog SHALL list exactly one row per Entro Select Provider tile label. Each row MUST use the exact UI tile string. The catalog MUST contain 58 unique tile labels matching the authoritative provider screenshot captured 2026-09-03.

#### Scenario: Unique tile rows

- **GIVEN** the generated Integration index
- **WHEN** tile labels are counted
- **THEN** there MUST be exactly 58 unique tile values
- **AND** no row MUST carry `targetSelection`

### Requirement: Integration path

Each Integration row MUST declare zero or more Integration paths. A path MUST represent a mutually exclusive choice visible on that tile's Entro connection form. When exactly one path exists, the index MUST omit `integrationPathNames` or list one name without a Lock gate. When more than one path exists, `integrationPathNames` MUST list every path name.

#### Scenario: Multi-path tile exposes path names

- **GIVEN** the Amazon Web Services Integration row
- **WHEN** the Skill catalog index is read
- **THEN** `integrationPathNames` MUST include CloudFormation, Terraform, and Assume Role

#### Scenario: Implicit singleton path

- **GIVEN** an Integration row with exactly one Integration path
- **WHEN** the index entry is generated
- **THEN** Connect MUST NOT require a path gate before Intro

### Requirement: Capture-required stub

An Integration row with `captureRequired: true` MUST NOT declare Integration paths, prep steps, or Typed actions. Connect MUST stop before Lock and request current connection-form screenshots.

#### Scenario: Stub stops Connect

- **GIVEN** a capture-required tile such as CircleCI
- **WHEN** an operator starts Connect for that tile
- **THEN** the agent MUST request form screenshots
- **AND** MUST NOT open the row catalog or run Typed actions

## MODIFIED Requirements

### Requirement: Catalog writer emits Skill catalog tree

`integration_catalog.py` SHALL write the ingest Integration index at
`documentation/integrations.json` as one JSON document of full rows (page paths
MAY remain). In the same run it SHALL write the Skill catalog in both
`entro-connect` skill trees as: a Skill catalog index at `integrations.json`; a
Tool install file at `tool-install.json` containing `toolInstall`; and one row
folder per Integration tile at `integrations/<kebab(tile)>/` with `catalog.json`
(the complete row object) and Skill-held artifacts beside it. The index SHALL
contain only `tile`, `summary`, `integrationPathNames`,
`optionalCapabilityNames`, `catalogPath`, and `captureRequired`. It MUST NOT
include `targetSelection`, `setupMethodNames`, `authenticationMethodNames`,
`coverageNames`, `prepSteps`, `typedActions`, `connectionFields`, or
`toolInstall`. `catalogPath` MUST be skill-root-relative and MUST exist. The
Skill catalog MUST NOT require markdown paths under `documentation/` for a
Connect run. Hand-edits of generated skill catalog files MUST be overwritten on
the next catalog write. Validation MUST fail if the tree is missing, if an
ingest target lacks a Row catalog, if index identity fields disagree with that
Row catalog, if the two skill trees differ, or if a skill tree still contains
`vendor/`.

_Rationale: ADR-0002 (apply)_

#### Scenario: Skill catalog tree is generated beside the ingest index

- **GIVEN** a successful catalog write
- **WHEN** `documentation/integrations.json` is regenerated
- **THEN** both skill trees MUST contain a Skill catalog index, a Tool install file, and one Row catalog per exact Integration tile
- **AND** `documentation/integrations.json` MUST remain one file of full rows

#### Scenario: Index is thin

- **GIVEN** a written Skill catalog index
- **WHEN** ingest validates the Skill catalog
- **THEN** each index entry MUST include `catalogPath` and `summary`
- **AND** no index entry MUST include `prepSteps`, `typedActions`, `connectionFields`, or `toolInstall`

#### Scenario: One folder per tile

- **GIVEN** GitHub Cloud - New, GitHub Cloud - Legacy, and GitHub Enterprise Server paths
- **WHEN** the Skill catalog is written
- **THEN** exactly one `integrations/github/catalog.json` MUST exist
- **AND** the index MUST list one GitHub tile with all three Integration path names

#### Scenario: Skill catalog is enough without the documentation tree

- **GIVEN** the Skill catalog tree and no `documentation/` markdown pages
- **WHEN** a Connect run Locks an Integration path
- **THEN** that Integration's Row catalog MUST include path-owned `summary`, `prepSteps.instruction`, and `connectionFields.obtainedHow`
- **AND** `tool-install.json` MUST include `toolInstall` for the locked Configuration tools

#### Scenario: vendor directory is rejected

- **GIVEN** a skill tree that still contains `vendor/`
- **WHEN** ingest validates the Skill catalog
- **THEN** validation MUST fail
