<!--
Delta spec — glossary terms promoted from discovery.
-->

## MODIFIED Requirements

### Requirement: Skill-held onboarding terms

The glossary SHALL define Skill-held onboarding artifact, Anonymous origin URL,
Doc-derived Typed action, Operator-only step, Temporary script copy,
Announcement, and Secret sink with the definitions in Term entries below. Specs
that describe Connect script runtime SHALL use Skill-held onboarding artifact
rather than treating a GitBook URL as the bytes that run.

#### Scenario: Specs use Skill-held onboarding artifact

- **GIVEN** a change authors documentation-ingest or integration-prep requirements about vendor scripts, zips, or captured snippets
- **WHEN** it names the file Connect executes
- **THEN** it MUST use Skill-held onboarding artifact
- **AND** it MUST NOT describe GitBook download as Connect runtime

#### Scenario: Specs use Anonymous origin URL

- **GIVEN** a change authors ingest requirements about the remote address used to detect drift
- **WHEN** it names that address
- **THEN** it MUST use Anonymous origin URL
- **AND** it MUST NOT treat a URL that contains `token=` as valid

#### Scenario: Specs distinguish Doc-derived Typed action and Operator-only step

- **GIVEN** a Prep step that is not covered by a Skill-held file
- **WHEN** a spec names how that step is owned
- **THEN** it MUST use Doc-derived Typed action or Operator-only step
- **AND** it MUST NOT leave the step unnamed

#### Scenario: Specs use Temporary script copy

- **GIVEN** a change authors Connect runtime requirements about changing names or skipping a menu on a pinned script
- **WHEN** it names that disposable file
- **THEN** it MUST use Temporary script copy
- **AND** it MUST NOT describe an in-place edit of the Skill-held file

#### Scenario: Specs use Announcement not approval for automated

- **GIVEN** a change authors requirements about what automated says before it runs a change
- **WHEN** it names that message
- **THEN** it MUST use Announcement
- **AND** it MUST NOT describe it as an Approve gate

#### Scenario: Specs use Secret sink for agent-run secret output

- **GIVEN** a change authors requirements about where a secret-producing command's output goes under automated
- **WHEN** it names that destination
- **THEN** it MUST use Secret sink
- **AND** it MUST NOT describe the secret as entering agent context, chat, or the Connect log

#### Scenario: Minting a credential does not make a step Operator-only

- **GIVEN** a Prep step whose Typed action is `secretProducing`
- **WHEN** a spec names who executes it under automated
- **THEN** it MUST NOT classify that step as an Operator-only step
- **AND** Operator-only step MUST remain reserved for steps with no Typed action

## Term entries

### Term: Operator-only step
**Context**: integration-prep
**Definition**: A Prep step the project does not automate because it has no Typed action — the platform exposes it only through its UI, or no documented command covers it — carrying a recorded reason and the evidence the operator reports.
**Aliases**: none
**Notes**: Absence of a Typed action is this classification once reason is present, not an unwritten gap. Minting a credential does not make a step Operator-only: a `secretProducing` Typed action is agent-run under automated through a Secret sink, and operator-run under supervised.

### Term: Announcement
**Context**: integration-prep
**Definition**: The message automated sends immediately before it runs a change — the same disclosure supervised puts above its gate (step, target, exact command, expected change, verification, rollback or impact), plus a statement that the agent is running it now.
**Aliases**: none
**Notes**: It asks for nothing and waits for nothing. Not an Approve gate. Supervised has no Announcement; automated has no per-change gate.

### Term: Secret sink
**Context**: integration-automation
**Definition**: The file outside the repository and both skill trees that an agent-run secret-producing command writes its output to instead of the terminal, so the secret never enters agent context, chat, or the Connect log.
**Aliases**: none
**Notes**: The agent reads back only named non-secret identifiers from it, discloses the path in chat so the operator vaults the secret, and deletes it once they confirm. The path MUST NOT be written to the Connect log. Not a vault and not a Temporary script copy.
