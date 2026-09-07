<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: entro-connect performs a Connect run

The project SHALL provide one model-invoked `entro-connect` skill that performs a
Connect run: Lock an Add New Account target, collect Operator inputs, introduce the
Integration, then execute one Operation mode and write a Connect log. The skill
MUST read the Skill catalog at `.agents/skills/entro-connect/integrations.json`
rather than inventing tiles, Coverages, Configuration tools, Connection details,
Prep steps, Operator inputs, or Typed actions. It MUST NOT open files under
`documentation/` to perform a Connect run.

#### Scenario: Ambiguous Microsoft intent is locked

- **GIVEN** the operator asks to connect Microsoft Copilot Studio
- **WHEN** the skill starts
- **THEN** it MUST Lock the Microsoft Ecosystem Add New Account target
- **AND** it MUST include the Copilot Studio Coverage in that Lock
- **AND** it MUST NOT treat Copilot Studio as an Add New Account target

#### Scenario: Skill does not read ingested pages

- **GIVEN** `documentation/` markdown is absent
- **WHEN** the skill Locks GitHub Cloud - New
- **THEN** it MUST still complete intro, Operation mode, and Connect log from the Skill catalog

#### Scenario: Intro names Connector deployment and needs

- **GIVEN** a completed Lock
- **WHEN** the skill introduces the Integration
- **THEN** it MUST explain the Integration from the row `summary`, name Connector deployment options from skill-local connector markdown, list Coverages on that row, list required access, Configuration tools with Fit, Prep step titles, Connection details field names, collected Operator inputs, and show an ASCII C4
- **AND** it MUST state that no configuration has been performed yet
- **AND** it MUST NOT install or configure a Connector
- **AND** it MUST NOT open `documentation/` pages

### Requirement: Intro is persisted before Operation mode

After Lock the skill SHALL create or append the Connect log, collect Operator inputs
during Intro, persist the same operator-facing Intro brief that was shown in chat,
and only then offer Operation mode. The brief MUST include purpose, Coverages,
topology, prerequisites, tools and probe status, names, fields, Prep outline,
safety boundary, and C4.

#### Scenario: Mode is not the first operator choice after Lock

- **GIVEN** a completed Lock
- **WHEN** the skill continues the Connect run
- **THEN** it MUST persist the Intro in the Connect log
- **AND** it MUST NOT offer Operation mode until that Intro exists in the file

### Requirement: Operation mode gates tools and automation

A Connect run SHALL use Operation mode `instructions`, `supervised`, or
`automated`. Automated MUST be offered only when every Prep step selected by the
Lock has a valid Typed action and every required Configuration tool has presence,
Capability probe, auth-check, and Platform identity contracts. When that plan is
incomplete, or when every Configuration tool is Fit `none`, the skill MUST offer
only instructions and supervised and MUST explain why automated is hidden.
Configuration tool install and auth-once SHALL run only for supervised and automated.
The skill SHALL pick tools by matching the locked Setup method when obvious,
otherwise the first Fit preferred, then usable CLI, then MCP.

#### Scenario: Incomplete typed-action plan hides automated

- **GIVEN** a Lock whose selected Prep steps lack a complete Typed action plan
- **WHEN** the skill offers Operation mode
- **THEN** the options MUST be instructions and supervised
- **AND** automated MUST NOT be offered

#### Scenario: Fit none hides automated

- **GIVEN** a Lock whose Configuration tools are only Fit `none`
- **WHEN** the skill offers Operation mode
- **THEN** the options MUST be instructions and supervised
- **AND** automated MUST NOT be offered

#### Scenario: GitHub Cloud New is not automated

- **GIVEN** the GitHub Cloud - New Lock whose `gh` Fit is `usable`
- **WHEN** the skill offers Operation mode
- **THEN** automated MUST NOT be offered

#### Scenario: Instructions skip tool install

- **GIVEN** the operator chooses instructions
- **WHEN** the skill writes the Connect log
- **THEN** it MUST NOT require Configuration tool install or auth-once

### Requirement: Instructions-only batch persists Intro per target

When the operator names several Add New Account targets and wants instructions
only, the skill SHALL Lock each target, persist Intro, and write one Connect log
per target. It MUST NOT require tool install, auth-once, or mutating execution.
Supervised and automated runs MUST stay sequential, one Lock at a time.

#### Scenario: Three instruction playbooks

- **GIVEN** the operator asks for instructions for AWS, Okta, and Slack
- **WHEN** the skill runs
- **THEN** it MUST write three Connect logs
- **AND** each Connect log MUST contain that target's persisted Intro
- **AND** it MUST NOT require tool login

#### Scenario: Supervised is sequential

- **GIVEN** the operator asks to supervise AWS and Okta in one message
- **WHEN** the skill runs
- **THEN** it MUST complete one Lock before starting the next

### Requirement: Connect log records evidence without secrets

Each Connect run SHALL write or append a Connect log at the repo root named
`entro-<tile-slug>` with optional target slug, gitignored via `entro-*.md`.
The file MUST be created after Lock and MUST receive Intro, Operator inputs,
Configuration plan, Platform identity, and Prep evidence as they occur.
Instructions mode SHALL persist the full safe playbook from Typed actions
(disclosures, targets, evidence checks, rollback or impact notes) with every
mutation operator-executed. Supervised and automated SHALL append a timestamped
run section with each Prep step's evidence. Re-runs MUST append. Secret field
values MUST NOT appear in the file.

#### Scenario: Re-run appends

- **GIVEN** `entro-github-cloud-new.md` already exists
- **WHEN** the operator runs entro-connect for GitHub Cloud - New again
- **THEN** the skill MUST append a new run section
- **AND** prior evidence MUST remain

#### Scenario: Platform identity is recorded on auth success

- **GIVEN** a Configuration tool auth check succeeds
- **WHEN** the skill records evidence
- **THEN** the Connect log MUST include the non-secret principal, service endpoint, and active tenant, org, account, project, or subscription scope
- **AND** it MUST NOT include a token or password

### Requirement: Tool presence is probed before install

For supervised and automated modes the skill SHALL run the catalog Capability
probe before offering install. A suitable existing installation MUST be reused.
An unsuitable installation MUST be recorded with the mismatch and gated as the
exact upgrade or dependency install. The skill MUST NOT offer to install a tool
that the probe already found suitable.

#### Scenario: Existing suitable tool is not reinstalled

- **GIVEN** the locked Configuration tool is on PATH and the Capability probe passes
- **WHEN** the skill reaches the tools step
- **THEN** it MUST record the detected installation in the Connect log
- **AND** it MUST NOT offer that tool's install command as the next action

### Requirement: Auth-once is checked then confirmed

For supervised and automated modes the skill SHALL run the catalog auth-check
and Platform identity query before requesting login. A valid session MUST skip
login and gate continue-with-this-environment versus re-authenticate or help.
An invalid session MUST request the catalog `authOnce` in the operator's
terminal and finish that message with Continue (check authentication) or Help
(authentication issues). Help MUST collect non-secret error output, diagnose it,
and return to that gate. The skill MUST NOT accept a login secret into session.

#### Scenario: Valid session skips login

- **GIVEN** the catalog auth-check reports an authenticated session
- **WHEN** the skill records Platform identity
- **THEN** it MUST skip a new login
- **AND** it MUST gate confirmation of the observed environment before configuration

#### Scenario: Operator requests help after login

- **GIVEN** the operator chose Help after `authOnce`
- **WHEN** non-secret CLI output is available
- **THEN** the skill MUST diagnose that output
- **AND** it MUST return to Continue or Help
- **AND** it MUST NOT treat authentication as complete until the auth-check succeeds

---

## MODIFIED Requirements

### Requirement: User-authenticated CLIs are the default automation path

When Integration prep is automated, the project SHALL prefer the target's official
CLI (or equivalent user-run tool) over custom API clients that would require the
agent to hold credentials. Automated Operation mode SHALL run only after the
operator's Configuration tool session is verified by the catalog auth-check and
the operator has confirmed Platform identity. The agent MUST execute only cataloged
Typed actions, never invented commands.

#### Scenario: Automation is offered for an Integration

- **GIVEN** an Integration with a usable official CLI and documented integration-prep
- **WHEN** a change adds automation for that Integration
- **THEN** the automation MUST assume the user has already authenticated that CLI locally

#### Scenario: Automated requires a complete typed-action plan

- **GIVEN** a Lock with a complete Typed action plan and required tool contracts
- **WHEN** the operator chooses automated
- **THEN** the skill MUST persist the Configuration plan before any mutation
- **AND** it MUST execute only cataloged Typed actions after per-change approval
- **AND** the agent MUST NOT collect the login secret into session

### Requirement: Agent does not handle secrets

Automation instructions and code SHALL not collect, store, log, or inject secret
values. The user's authenticated session is the credential boundary. A Typed action
that produces a one-time secret MUST remain operator-executed even in automated
mode; the agent SHALL verify only non-secret metadata afterward.

#### Scenario: A step requires a secret the CLI does not already have

- **GIVEN** an automation step cannot proceed without a secret
- **WHEN** the agent would otherwise prompt for or write that secret
- **THEN** the agent MUST stop and ask the user to complete that step in their CLI or vault — not accept the secret into the agent session

#### Scenario: Secret-producing action stays with the operator

- **GIVEN** a Typed action whose result is a one-time secret value
- **WHEN** Operation mode is automated
- **THEN** the operator MUST execute that action
- **AND** the Connect log MUST record only non-secret identifiers
