<!--
Delta spec — glossary terms promoted from discovery.
-->

## MODIFIED Requirements

### Requirement: Skill-held onboarding terms

The glossary SHALL define Skill-held onboarding artifact, Anonymous origin URL,
Local onboarding fork, Doc-derived Typed action, Operator-only step, Uncataloged
Prep step, Runtime Doc-derived action, Temporary script copy, Announcement, and
Secret sink with the definitions in Term entries below. Specs that describe
Connect script runtime SHALL use Skill-held onboarding artifact rather than
treating a GitBook URL as the bytes that run.

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
- **THEN** it MUST use Doc-derived Typed action, Operator-only step, or Uncataloged Prep step
- **AND** it MUST NOT leave the step unnamed

#### Scenario: Specs use Uncataloged Prep step for a missing reason

- **GIVEN** a Prep step with no Typed action whose author recorded no reason for withholding one
- **WHEN** a spec names that step
- **THEN** it MUST use Uncataloged Prep step
- **AND** it MUST NOT call it an Operator-only step

#### Scenario: Specs use Runtime Doc-derived action for a derived command

- **GIVEN** a change authors requirements about a mutation the agent derives during a run to cover an Uncataloged Prep step
- **WHEN** it names that mutation
- **THEN** it MUST use Runtime Doc-derived action
- **AND** it MUST NOT describe it as an invented or ad-hoc command
- **AND** it MUST NOT call it a Typed action

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
- **AND** Operator-only step MUST remain reserved for steps carrying an authored reason

---

## Term entries

### Term: Operator-only step
**Context**: integration-prep
**Definition**: A Prep step the project does not automate because the platform exposes it only through its UI, or because its documented command route is merge-sensitive enough that Connect declines to run it, carrying an authored reason and the evidence the operator reports.
**Aliases**: none
**Notes**: An authored reason is necessary for this classification. Absence of a Typed action alone is an Uncataloged Prep step, not this. Minting a credential does not make a step Operator-only: a `secretProducing` Typed action is agent-run under automated through a Secret sink, and operator-run under supervised.

### Term: Uncataloged Prep step
**Context**: integration-prep, documentation-ingest
**Definition**: A Prep step carrying neither a Typed action nor an authored Operator-only reason, emitted with an `uncataloged` classification that carries `evidence`.
**Aliases**: none
**Notes**: Describes the Skill catalog, not the vendor. Under automated the agent covers it with a Runtime Doc-derived action after one consent gate; under supervised the operator runs the disclosed derived command. The catalog writer MUST NOT convert one into an Operator-only step by supplying a default reason.

### Term: Runtime Doc-derived action
**Context**: integration-prep, integration-automation
**Definition**: A mutation the agent derives from vendor documentation during a Connect run to cover an Uncataloged Prep step, disclosed with its documentation source and consented once before it runs.
**Aliases**: none
**Notes**: Not a Typed action: it is derived per run rather than cataloged, and it is the only mutation automated gates. MUST NOT be composed from anything but vendor documentation; when documentation covers no command, the step falls back to operator execution with that absence recorded. A secret-producing one uses a Secret sink like any other.
