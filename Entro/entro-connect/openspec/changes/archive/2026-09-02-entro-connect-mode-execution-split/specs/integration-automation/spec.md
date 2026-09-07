## ADDED Requirements

### Requirement: Operation mode gates tools and the execution actor

A Connect run SHALL use Operation mode `instructions`, `supervised`, or
`automated`. Automated MUST be offered only when every Prep step selected by the
Lock has a valid Typed action and every required Configuration tool has presence,
Capability probe, auth-check, and Platform identity contracts. When that plan is
incomplete, or when every Configuration tool is Fit `none`, the skill MUST offer
only instructions and supervised and MUST explain why automated is hidden.
Configuration tool install and auth-once SHALL run only for supervised and automated.
The skill SHALL pick tools by matching the locked Setup method when obvious,
otherwise the first Fit preferred, then usable CLI, then MCP. Automated SHALL
execute every cataloged Typed action in the plan itself, each announced
immediately before it runs and without a per-change gate. Supervised SHALL
disclose and gate each action and then have the operator execute it, and the
skill MUST NOT execute a mutation in that mode. Instructions (playbook) MUST NOT
execute mutations.

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

#### Scenario: The two modes differ on who executes

- **GIVEN** a cataloged Typed action in the persisted Configuration plan
- **WHEN** the skill reaches that action
- **THEN** automated MUST run the disclosed mutation itself after announcing it
- **AND** supervised MUST hand the approved command to the operator
- **AND** the two modes MUST differ on who executes

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
- **AND** it MUST execute only cataloged Typed actions, each announced before it runs
- **AND** the agent MUST NOT collect the login secret into session

### Requirement: Agent does not handle secrets

Automation instructions and code SHALL not collect, store, log, or inject secret
values. The user's authenticated session is the credential boundary, and signing
in SHALL stay operator-executed in every Operation mode. A Typed action that
produces a one-time secret MAY be executed by the agent in automated mode, in
which case the skill SHALL route its output to a Secret sink outside the
repository and both skill trees, read back only named non-secret identifiers,
and delete that file once the operator confirms the secret is vaulted. The secret
value MUST NOT enter agent context, chat, or the Connect log. When the command
cannot withhold the secret from its terminal output, the skill MUST NOT run it
and SHALL hand that step to the operator. In supervised mode the operator
executes the action and the agent verifies only non-secret metadata afterward.

#### Scenario: A step requires a secret the CLI does not already have

- **GIVEN** an automation step cannot proceed without a secret the operator holds
- **WHEN** the agent would otherwise prompt for or write that secret
- **THEN** the agent MUST stop and ask the user to complete that step in their CLI or vault — not accept the secret into the agent session

#### Scenario: Automated executes a secret-producing action

- **GIVEN** a Typed action whose result is a one-time secret value
- **WHEN** Operation mode is automated
- **THEN** the agent MUST execute that action itself
- **AND** the command output MUST go to a Secret sink rather than into agent context
- **AND** the Connect log MUST record only non-secret identifiers

#### Scenario: Secret-producing action stays with the operator

- **GIVEN** a Typed action whose result is a one-time secret value
- **WHEN** Operation mode is supervised
- **THEN** the operator MUST execute that action
- **AND** the Connect log MUST record only non-secret identifiers

### Requirement: Connect log records evidence without secrets

Each Connect run SHALL write or append a Connect log at the repo root named
`entro-<tile-slug>` with optional target slug, gitignored via `entro-*.md`.
The file MUST be created after Lock and MUST receive Intro, Operator inputs,
Configuration plan, Platform identity, and Prep evidence as they occur.
Instructions mode SHALL persist the full safe playbook from Typed actions
(disclosures, targets, evidence checks, rollback or impact notes) with every
mutation operator-executed. Supervised and automated SHALL append a timestamped
run section with each Prep step's evidence and the execution actor, the agent
under automated and the operator under supervised. Re-runs MUST append. Secret
field values MUST NOT appear in the file, nor MUST a Secret sink path.

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

#### Scenario: Execution actor is recorded per step

- **GIVEN** a completed Prep step in supervised or automated mode
- **WHEN** the skill records that step
- **THEN** the Connect log MUST name who executed it
- **AND** it MUST NOT record a secret value or a Secret sink path

### Requirement: Auth-once is checked then confirmed

For supervised and automated modes the skill SHALL run the catalog auth-check
and Platform identity query before requesting login. A valid session MUST skip
login and gate continue-with-this-environment versus re-authenticate or help.
An invalid session MUST request the catalog `authOnce` in the operator's
terminal, in automated mode as well as supervised, and finish that message with
Continue (check authentication) or Help (authentication issues). Help MUST
collect non-secret error output, diagnose it, and return to that gate. The skill
MUST NOT accept a login secret into session.

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

#### Scenario: Automated still asks the operator to sign in

- **GIVEN** Operation mode is automated
- **AND** the catalog auth-check reports no valid session
- **WHEN** the skill reaches the tools step
- **THEN** it MUST request the catalog `authOnce` in the operator's terminal
- **AND** it MUST NOT run the login itself

---

## REMOVED Requirements

### Requirement: Operation mode gates tools and automation

**Reason**: Its execution rule — supervised and automated both run non-secret-producing actions after Approve, and the two modes MUST NOT differ on who executes — is exactly what this change reverses. Replaced by "Operation mode gates tools and the execution actor", which keeps the mode-offering and tool-picking rules unchanged and states the new split.

**Migration**: None for operators beyond the mode behavior itself. Specs referencing the old header MUST use the new one.
