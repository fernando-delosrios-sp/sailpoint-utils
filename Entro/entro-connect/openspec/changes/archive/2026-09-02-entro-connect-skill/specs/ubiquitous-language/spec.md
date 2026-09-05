<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Connect run catalog terms

The glossary SHALL define Connect log, Operation mode, Prep step, Lock, Skill
catalog, Operator input, Typed action, Platform identity, Configuration plan, and
Capability probe with the definitions in Term entries below. Notes on Connection
details SHALL state that vendor-specific fields live on the Integration index as
`connectionFields` (`name`, `secret`, `obtainedHow`) and that Worker Group is a
global field map rule, not a per-row catalog item.

#### Scenario: Specs use Connect log not session file

- **GIVEN** a change authors skill or ingest requirements about the markdown file a Connect run writes
- **WHEN** it names that file
- **THEN** it MUST use Connect log
- **AND** it MUST NOT treat the Connect log as the Integration index

#### Scenario: Specs use Operation mode

- **GIVEN** a change authors skill requirements about instructions, supervised, or automated
- **WHEN** it names those paths
- **THEN** it MUST use Operation mode
- **AND** it MUST NOT use manual as the canonical name for instructions

#### Scenario: Specs use Prep step not setup method

- **GIVEN** a change authors documentation-ingest requirements about ordered target-side actions
- **WHEN** it names those catalog items
- **THEN** it MUST use Prep step
- **AND** it MUST NOT call a Prep step a Setup method

#### Scenario: Specs use Lock not tile alone

- **GIVEN** a change authors skill requirements about which Integration a run configures
- **WHEN** it names the confirmed selection
- **THEN** it MUST use Lock
- **AND** it MUST NOT treat a Coverage as an Add New Account target

#### Scenario: Specs use Skill catalog

- **GIVEN** a change authors skill requirements about which JSON file entro-connect reads
- **WHEN** it names that file
- **THEN** it MUST use Skill catalog
- **AND** it MUST NOT require the skill to open `documentation/` markdown

#### Scenario: Specs use Operator input not guessed labels

- **GIVEN** a change authors skill requirements about names the operator supplies
- **WHEN** it names those catalog items
- **THEN** it MUST use Operator input
- **AND** it MUST NOT infer required names only from `obtainedHow` prose

#### Scenario: Specs use Typed action not ad-hoc command

- **GIVEN** a change authors automation requirements about executable Integration prep
- **WHEN** it names those catalog items
- **THEN** it MUST use Typed action
- **AND** it MUST NOT store a `command` field on a Prep step

#### Scenario: Specs use Platform identity

- **GIVEN** a change authors skill requirements about which environment a Configuration tool is authenticated to
- **WHEN** it names that evidence
- **THEN** it MUST use Platform identity
- **AND** it MUST NOT treat a token cache as the recorded evidence

#### Scenario: Specs use Configuration plan not Intro outline

- **GIVEN** a change authors skill requirements about the ordered mutations to execute
- **WHEN** it names that list
- **THEN** it MUST use Configuration plan
- **AND** it MUST NOT treat the Intro outline as the executable plan

#### Scenario: Specs use Capability probe

- **GIVEN** a change authors skill requirements about whether a Configuration tool is already suitable
- **WHEN** it names that check
- **THEN** it MUST use Capability probe
- **AND** it MUST NOT treat any on-PATH executable as automatically suitable

#### Scenario: Connection details notes name the index

- **GIVEN** the glossary entry for Connection details
- **WHEN** a reader uses that term after this change archives
- **THEN** the Notes MUST say vendor-specific fields are `connectionFields` (`name`, `secret`, `obtainedHow`) on the Integration index
- **AND** the Notes MUST say Worker Group is a global field-map rule

## Term entries

### Term: Connect log
**Context**: integration-automation
**Definition**: A gitignored markdown file at the repository root (`entro-*.md`) that records one Add New Account target's Intro, Operator inputs, Configuration plan, Platform identity, and Prep evidence.
**Aliases**: session file
**Notes**: Created after Lock and updated as the run proceeds. Secret field values are never stored. Not the Integration index. Re-runs append. One file per target slug.

### Term: Operation mode
**Context**: integration-automation
**Definition**: How a Connect run performs Integration prep: instructions (full safe playbook, operator executes every mutation), supervised (same disclosures; operator executes after each approval), or automated (agent runs cataloged Typed actions after per-change approval).
**Aliases**: none
**Notes**: Automated is offered only when the Lock has a complete Typed action plan and required tool contracts. Fit none or an incomplete plan hides automated. Not a Setup method.

### Term: Prep step
**Context**: documentation-ingest
**Definition**: One curated item in `prepSteps`: title, instruction (distilled what-to-do), and non-secret evidence bound. Lives on a Setup method when the row has Setup methods, otherwise on the row. Coverages may add extra Prep steps.
**Aliases**: none
**Notes**: Sufficient without ingested pages. MUST NOT use a `command` field. Typed actions bind to Prep steps. Not a Setup method, not Connection details, not a Coverage.

### Term: Skill catalog
**Context**: integration-automation
**Definition**: The generated copy of the Integration index at `.agents/skills/entro-connect/integrations.json` that entro-connect reads for a Connect run.
**Aliases**: skill integrations.json
**Notes**: Written by `integration_catalog.py` in the same run as `documentation/integrations.json`. Hand-edits are overwritten. The skill MUST NOT read `documentation/` markdown. The ingest index MAY keep page paths for the documentation tree; a Connect run MUST NOT need them.

### Term: Lock
**Context**: integration-automation
**Definition**: The confirmed Add New Account target for one Connect run: tile and target selection, Coverages to include (default none), and Setup method or Authentication method when the row has two or more of either.
**Aliases**: none
**Notes**: A Coverage is never a Lock by itself. “Microsoft Copilot Studio” locks Microsoft Ecosystem plus that Coverage.

### Term: Operator input
**Context**: integration-automation
**Definition**: A cataloged non-secret value the operator supplies during Intro, identified by key, with prompt, purpose, validation, and optional default.
**Aliases**: naming decision
**Notes**: Typed actions and Connection details reference the key. Secrets are never Operator inputs.

### Term: Typed action
**Context**: integration-automation
**Definition**: A cataloged Integration-prep action bound to a Prep step, with preview or an explicit no-preview statement, mutation, target, expected change, verification, rollback or irreversible-impact note, and official source.
**Aliases**: none
**Notes**: Executable definitions are immutable at run time. External scripts are pinned by URL, version, and checksum. Secret-producing actions stay operator-executed.

### Term: Platform identity
**Context**: integration-automation
**Definition**: Non-secret evidence that a Configuration tool session is authenticated: principal plus service endpoint and active tenant, org, account, project, or subscription scope.
**Aliases**: connected environment
**Notes**: Recorded in the Connect log after a successful auth-check. Not a token, password, or secret.

### Term: Configuration plan
**Context**: integration-automation
**Definition**: The exact ordered list of tools, Typed actions, targets, expected changes, and evidence persisted after Operator inputs and Operation mode are settled, before any mutation.
**Aliases**: exact plan
**Notes**: Distinct from the Intro outline. Adjust/replan may change Operator inputs or remaining Operation mode, not Typed action definitions.

### Term: Capability probe
**Context**: integration-automation
**Definition**: A cataloged safe check that a Configuration tool is present and suitable, including required modules or plugins. A minimum version is stored only when the vendor requires one.
**Aliases**: tool probe
**Notes**: A suitable installation is reused. Unsuitable installations are explained and gated as the exact upgrade or dependency.

### Term: Connection details
**Context**: connection-details
**Definition**: The fields Entro requires to complete an Integration (base URL, tenant, identifiers, and references to credentials the user supplies).
**Aliases**: connection fields, Entro connection form, field map
**Notes**: Vendor-specific fields are listed on the Integration index as `connectionFields` (`name`, `secret`, `obtainedHow`). Worker Group (Connector) is a global field-map rule and MUST NOT be copied onto every row. Operator-chosen non-secret labels are Operator inputs bound to those fields. Specs, Skill catalog, and Connect logs describe field names and how to obtain values; they MUST NOT store secret values. `obtainedHow` MUST be usable without opening ingested pages.
