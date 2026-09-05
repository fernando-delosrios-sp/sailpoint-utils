<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Connect run folder holds persisted files

Each Connect run SHALL resolve a Connect run folder named `entro-connect` as a
child of the current working directory. When that path would be either Skill
catalog tree, the skill MUST use the repository-root `entro-connect` directory
instead. The repository `.gitignore` SHALL list `/entro-connect/` so the folder
is not committed. The skill SHALL create or append the Connect log, Temporary
script copies, and Secret sinks only inside that folder. It MUST NOT write a new
Connect log at the repository root. Connect log names SHALL remain
`entro-<tile-slug>` with an optional Integration-path slug.

#### Scenario: Connect log is created in the Connect run folder

- **GIVEN** a completed Lock for Okta
- **WHEN** the skill creates the Connect log
- **THEN** the file MUST be `entro-okta.md` inside the Connect run folder
- **AND** it MUST NOT create `entro-okta.md` at the repository root

#### Scenario: Skill catalog parent falls back to repository root

- **GIVEN** the current working directory is `.agents/skills`
- **WHEN** the skill resolves the Connect run folder
- **THEN** it MUST use the repository-root `entro-connect` directory
- **AND** it MUST NOT write run files into `.agents/skills/entro-connect`

#### Scenario: Gitignore covers only the repo-root run folder

- **GIVEN** the repository `.gitignore`
- **WHEN** a Connect run persists files
- **THEN** `.gitignore` MUST contain `/entro-connect/`
- **AND** `skills/entro-connect` MUST remain a tracked Skill catalog tree

---

## MODIFIED Requirements

### Requirement: Agent does not handle secrets

Automation instructions and code SHALL not collect, store, log, or inject secret
values. The user's authenticated session is the credential boundary, and signing
in SHALL stay operator-executed in every Operation mode. A Typed action that
produces a one-time secret MAY be executed by the agent in automated mode, in
which case the skill SHALL route its output to a Secret sink in the Connect run
folder, read back only named non-secret identifiers,
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
- **AND** the command output MUST go to a Secret sink in the Connect run folder rather than into agent context
- **AND** the Connect log MUST record only non-secret identifiers

#### Scenario: Secret-producing action stays with the operator

- **GIVEN** a Typed action whose result is a one-time secret value
- **WHEN** Operation mode is supervised
- **THEN** the operator MUST execute that action
- **AND** the Connect log MUST record only non-secret identifiers

### Requirement: Connect log records evidence without secrets

Each Connect run SHALL write or append a Connect log in the Connect run folder
named `entro-<tile-slug>` with an optional Integration-path slug, gitignored via
`/entro-connect/`.
The file MUST be created after Lock and MUST receive Intro, Operator inputs,
Configuration plan, Platform identity, and Prep evidence as they occur.
Instructions mode SHALL persist the full safe playbook from Typed actions
(disclosures, targets, evidence checks, rollback or impact notes) with every
mutation operator-executed. Supervised and automated SHALL append a timestamped
run section with each Prep step's evidence and the execution actor, the agent
under automated and the operator under supervised. Re-runs MUST append. Secret
field values MUST NOT appear in the file, nor MUST a Secret sink path.

#### Scenario: Re-run appends

- **GIVEN** `entro-github-cloud-new.md` already exists in the Connect run folder
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
