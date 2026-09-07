<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Integration index lists Connection details

Each Integration index row SHALL carry a `connectionFields` list of vendor-specific
Connection details for that Add New Account target. Each item SHALL have `name`,
`secret` (boolean), and `obtainedHow` (how the operator gets the value, with no
secret value inlined). The list MUST NOT include Worker Group (Connector); that
field is a global rule. Environment, Display Name, and other Entro-owned labels
SHALL appear only when that target's connection form uses those labels. An
operator-chosen non-secret field SHALL also be an Operator input keyed from that
field. Validation MUST reject a missing list, an item without `name` or
`obtainedHow`, or a secret value in any field. Items MUST NOT require opening an
ingested documentation page.

#### Scenario: Every target lists connection fields

- **GIVEN** the curated catalog of Add New Account targets
- **WHEN** the Integration index is written
- **THEN** each row MUST include a `connectionFields` array
- **AND** each item MUST have `name`, `secret`, and `obtainedHow`

#### Scenario: Worker Group is not catalogued per row

- **GIVEN** any Add New Account target
- **WHEN** the Integration index is written
- **THEN** no `connectionFields` item MUST have the name Worker Group or Worker Group (Connector)

#### Scenario: Okta vendor fields are named

- **GIVEN** the Okta Add New Account target
- **WHEN** the Integration index is written
- **THEN** `connectionFields` MUST include Okta Domain and Client Id
- **AND** each of those items MUST include `obtainedHow` text sufficient without opening `documentation/`
- **AND** a client secret field MUST have `secret` true if the form collects one

#### Scenario: Coverages do not add Connection details

- **GIVEN** the Microsoft Ecosystem row and its Copilot Studio Coverage
- **WHEN** the Integration index is written
- **THEN** Copilot Studio MUST NOT list `connectionFields`
- **AND** the parent row MUST carry the Azure connection form fields

### Requirement: Integration index lists Prep steps

Each Integration index row SHALL carry ordered `prepSteps` either on each Setup
method when the row has one or more Setup methods, or on the row when it has none.
Each Prep step SHALL have `title`, `instruction` (what to do, distilled, no secret
values), and `evidence` naming the non-secret observable that the step is done.
Each row SHALL have a `summary` of what the Integration is, sufficient for the
skill intro without ingested pages. Coverages MAY list additive `prepSteps`; an
empty Coverage list means inherit the parent steps only. Validation MUST reject a
row that has neither row-level nor setup-method `prepSteps`, a missing `summary`,
a step without `instruction`, or a step that embeds a secret value. Prep steps
MUST NOT include a `command` field.

#### Scenario: Row without setup methods has prepSteps

- **GIVEN** an Add New Account target whose `setupMethods` list is empty
- **WHEN** the Integration index is written
- **THEN** that row MUST include a non-empty `prepSteps` list
- **AND** each step MUST have `title`, `instruction`, and `evidence`
- **AND** the row MUST include `summary`

#### Scenario: Setup methods own their steps

- **GIVEN** the AWS Add New Account target with CloudFormation and Manual Assume Role Setup methods
- **WHEN** the Integration index is written
- **THEN** each Setup method MUST have its own `prepSteps` list
- **AND** the row MUST NOT also duplicate those lists at row level

#### Scenario: Copilot Studio adds permission steps

- **GIVEN** the Microsoft Ecosystem Copilot Studio Coverage
- **WHEN** the Integration index is written
- **THEN** that Coverage MUST list `prepSteps` for the extra Graph permissions
- **AND** those steps MUST be additive to the parent Azure app Prep steps
- **AND** each Coverage step MUST include `instruction` text

#### Scenario: Commands are not stored on Prep steps

- **GIVEN** any Prep step in the Integration index
- **WHEN** the index is validated
- **THEN** the step MUST NOT contain a `command` field
- **AND** `evidence` and `instruction` MUST NOT contain a token-shaped secret

### Requirement: Catalog writer emits a Skill catalog

`integration_catalog.py` SHALL write the ingest Integration index at
`documentation/integrations.json` and a Skill catalog at
`.agents/skills/entro-connect/integrations.json`. The Skill catalog SHALL contain
every Add New Account target with `summary`, Configuration tools, Coverages,
`connectionFields`, `prepSteps`, Operator inputs, Typed actions when present,
and `toolInstall`. The Skill catalog MUST NOT require markdown paths under
`documentation/` for a Connect run. Hand-edits of the Skill catalog MUST be
overwritten on the next catalog write. Validation MUST fail if the Skill catalog
is missing, lacks a target present in the ingest index, or lacks `summary` /
fields / steps on a target.

#### Scenario: Skill catalog is generated beside the ingest index

- **GIVEN** a successful catalog write
- **WHEN** `documentation/integrations.json` is regenerated
- **THEN** `.agents/skills/entro-connect/integrations.json` MUST be written in the same run
- **AND** every ingest-index tile and targetSelection pair MUST appear in the Skill catalog

#### Scenario: Skill catalog is enough without the documentation tree

- **GIVEN** the Skill catalog file and no `documentation/` markdown pages
- **WHEN** a Connect run Locks a target
- **THEN** `summary`, `prepSteps.instruction`, `connectionFields.obtainedHow`, and `toolInstall` MUST be present for that target

### Requirement: Integration index lists Operator inputs

Each Add New Account target SHALL list Operator inputs for every non-secret
naming or label decision the Connect run must collect (`key`, prompt, purpose,
validation, optional default, `secret` false). Typed actions and Connection
details SHALL reference those keys. Validation MUST reject a secret Operator
input and MUST reject a Fit `preferred` selectable path that needs a name the
catalog does not declare as an Operator input.

#### Scenario: Operator-chosen labels are typed inputs

- **GIVEN** a row whose Connection details include an operator-chosen Environment or Display Name
- **WHEN** the Integration index is written
- **THEN** that row MUST include an Operator input whose key binds to that field
- **AND** the input MUST have `secret` false

### Requirement: Integration index lists Typed actions for preferred paths

A selectable Fit `preferred` Setup method, row, or Coverage path SHALL carry Typed
actions that cover every selected Prep step. Each Typed action SHALL include
preview metadata (or an explicit no-preview statement), mutation, target, expected
change, verification, rollback or irreversible-impact note, official source URL,
retrieval or version date, and whether the action produces a secret. External
scripts SHALL be pinned by URL, version, and checksum. Validation MUST fail if Fit
remains `preferred` without that complete plan. An incomplete path MUST have Fit
corrected to `usable` or `none` with rationale rather than remaining preferred.

#### Scenario: Preferred path has a complete action plan

- **GIVEN** a selectable path whose Configuration tools include Fit `preferred`
- **WHEN** the Integration index is validated
- **THEN** every Prep step on that path MUST have a Typed action
- **AND** validation MUST fail if any required action field is missing

#### Scenario: Incomplete preferred Fit is rejected

- **GIVEN** a path marked Fit `preferred` that lacks a Typed action for a Prep step
- **WHEN** the index is validated
- **THEN** validation MUST fail
- **AND** the author MUST correct Fit to `usable` or `none` with rationale before the catalog is accepted

### Requirement: Tool install catalog carries probes and identity

Each `toolInstall` entry SHALL include a presence check, a Capability probe,
an auth-check, and a Platform identity query, plus existing `authOnce`,
`credentialBoundary`, and install docs. The skill MUST execute only those
cataloged checks. Each probe and action SHALL record an official source URL and
retrieval or version date.

#### Scenario: Azure CLI has an identity query

- **GIVEN** the `az` `toolInstall` entry
- **WHEN** the Skill catalog is written
- **THEN** it MUST include presence, Capability probe, auth-check, and Platform identity fields
- **AND** those fields MUST NOT require opening `documentation/`
