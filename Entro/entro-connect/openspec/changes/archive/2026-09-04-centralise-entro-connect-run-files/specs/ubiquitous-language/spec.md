<!--
Delta spec — glossary terms promoted from discovery.
-->

## MODIFIED Requirements

### Requirement: Connect run catalog terms

The glossary SHALL define Connect log, Connect run folder, Operation mode, Prep
step, Lock, Skill catalog, Operator input, Typed action, Platform identity,
Configuration plan, and Capability probe with the definitions in Term entries
below. Notes on Connection details SHALL state that vendor-specific fields live
on the locked Integration path as `connectionFields` (`name`, `secret`,
`obtainedHow`), shared tile fields may be added, and Worker Group is a global
field-map rule.

#### Scenario: Specs use Connect log not session file

- **GIVEN** a change authors skill or ingest requirements about the markdown file a Connect run writes
- **WHEN** it names that file
- **THEN** it MUST use Connect log
- **AND** it MUST NOT treat the Connect log as the Integration index

#### Scenario: Specs use Connect run folder not repo root dump

- **GIVEN** a change authors skill requirements about where a Connect run writes files
- **WHEN** it names that directory
- **THEN** it MUST use Connect run folder
- **AND** it MUST NOT treat a Skill catalog tree as the Connect run folder

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
- **AND** it MUST NOT treat an Optional capability as an Integration

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
- **THEN** the Notes MUST say vendor-specific fields are `connectionFields` (`name`, `secret`, `obtainedHow`) on the locked Integration path
- **AND** the Notes MUST say Worker Group is a global field-map rule

---

## Term entries

### Term: Connect run folder
**Context**: integration-automation
**Definition**: The directory named `entro-connect` under the current working directory that holds every file a Connect run writes.
**Aliases**: none
**Notes**: Falls back to the repository-root `entro-connect` directory when the cwd-relative path would be a Skill catalog tree. Gitignored as `/entro-connect/`. Not `.agents/skills/entro-connect` and not `skills/entro-connect`.

### Term: Connect log
**Context**: integration-automation
**Definition**: A gitignored markdown file in the Connect run folder (`entro-<tile-slug>` with an optional Integration-path slug) that records one Lock's Intro, Operator inputs, Configuration plan, Platform identity, and Prep evidence.
**Aliases**: session file
**Notes**: Created after Lock and updated as the run proceeds. Secret field values are never stored. Not the Integration index. Re-runs append. One file per Lock slug.

### Term: Secret sink
**Context**: integration-automation
**Definition**: The file in the Connect run folder that an agent-run secret-producing command writes its output to instead of the terminal, so the secret never enters agent context, chat, or the Connect log.
**Aliases**: none
**Notes**: Filename prefix `sink-`. The agent reads back only named non-secret identifiers from it, discloses the path in chat so the operator vaults the secret, and deletes it once they confirm. The path MUST NOT be written to the Connect log. Not a vault and not a Temporary script copy. Not a Skill catalog tree file.

### Term: Temporary script copy
**Context**: integration-prep
**Definition**: A disposable copy of a pinned Skill-held onboarding artifact, used only to bind names or skip an interactive menu for one Connect run.
**Aliases**: none
**Notes**: Created after the original checksum matches. Lives in the Connect run folder with a `tmp-` filename prefix. Discarded after the step. MUST NOT be committed or written over `script.skillPath`. Not a Local onboarding fork.
