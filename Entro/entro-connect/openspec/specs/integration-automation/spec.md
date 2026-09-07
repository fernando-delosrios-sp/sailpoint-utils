# integration-automation

## Purpose

Optional CLI- or script-based Integration prep. The user authenticates vendor tools;
the agent does not handle secrets. Connect Intro uses an Intro C4 mermaid fence.
## Requirements
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

### Requirement: Connect run folder holds persisted files

Each Connect run SHALL resolve a Connect run folder named `integrationConfig` as a
child of the current working directory. When the current working directory is
inside either Skill catalog tree, the skill MUST use the repository-root
`integrationConfig` directory instead. The repository `.gitignore` SHALL list
`/integrationConfig/` so the folder is not committed. The skill SHALL create or append the Connect log, Temporary
script copies, and Secret sinks only inside that folder. It MUST NOT write a new
Connect log at the repository root. Connect log names SHALL remain
`entro-<tile-slug>` with an optional Integration-path slug.

#### Scenario: Connect log is created in the Connect run folder

- **GIVEN** a completed Lock for Okta
- **WHEN** the skill creates the Connect log
- **THEN** the file MUST be `entro-okta.md` inside the Connect run folder
- **AND** it MUST NOT create `entro-okta.md` at the repository root

#### Scenario: Skill catalog tree falls back to repository root

- **GIVEN** the current working directory is `.agents/skills/entro-connect`
- **WHEN** the skill resolves the Connect run folder
- **THEN** it MUST use the repository-root `integrationConfig` directory
- **AND** it MUST NOT write run files into `.agents/skills/entro-connect`

#### Scenario: Gitignore covers only the repo-root run folder

- **GIVEN** the repository `.gitignore`
- **WHEN** a Connect run persists files
- **THEN** `.gitignore` MUST contain `/integrationConfig/`
- **AND** `skills/entro-connect` MUST remain a tracked Skill catalog tree

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

### Requirement: Intro C4 is a mermaid fence

When entro-connect introduces an Integration, it SHALL include the Intro C4 in
chat and in the Connect log as a mermaid `flowchart` fence that draws the locked
Integration's Configuration topology. The fence SHALL use these node roles: the
Identity object Entro authenticates as, the permission grants attached to it, the
reach those grants cover, the credential the operator carries to Entro, and the
Entro side — the Connection and its Connector. Every node MUST be derived from
the locked Integration path and enabled Optional capabilities: Identity object
and permission grants from Typed action `expectedChange` and `target`, reach from
that path and enabled Optional capabilities and their Typed action targets, the
credential from applicable `connectionFields`, and the Connector from `hosting`.
A role the locked path does not name MUST be omitted rather than invented.
Disabled Optional capabilities MUST NOT appear as reach. Secret Connection details
MUST appear by field name only, never as a value. The fence MUST separate the
vendor boundary from Entro using subgraphs and MUST assign C4 roles with
`classDef`. It MUST NOT draw the Connect run machinery — Operator, Agent +
entro-connect, Skill catalog, Vendor CLI / MCP. It MUST NOT use ASCII arrows as
the Intro C4. It MUST NOT write a `.drawio` file for the Connect run.

#### Scenario: Intro shows mermaid not ASCII

- **GIVEN** a completed Lock
- **WHEN** the skill introduces the Integration
- **THEN** the Intro in chat MUST contain a mermaid `flowchart` fence for the
  Intro C4
- **AND** the Connect log MUST contain the same fence
- **AND** that section MUST NOT be an ASCII arrow sketch

#### Scenario: Intro C4 is not a per-run draw.io

- **GIVEN** a completed Lock
- **WHEN** the skill persists Intro
- **THEN** it MUST NOT create a `.drawio` beside the Connect log

#### Scenario: Intro C4 shows what the Integration needs configured

- **GIVEN** a Lock on Microsoft Ecosystem with the Copilot Studio Optional
  capability enabled during Prep
- **WHEN** the skill draws the Intro C4
- **THEN** the fence MUST name the Entra app registration as the Identity object
- **AND** it MUST show its admin-consented Graph permissions and Azure roles as
  permission grants
- **AND** it MUST show the Dataverse environments and SharePoint / OneDrive as
  reach
- **AND** it MUST show the Entro Connection with its Connection detail names and
  the Worker Group kind derived from `hosting`

#### Scenario: Two Integrations draw different fences

- **GIVEN** one Connect run locked on Microsoft Ecosystem and another locked on a
  different Integration
- **WHEN** each run draws its Intro C4
- **THEN** the two fences MUST differ in their nodes
- **AND** neither MUST be a copy of an example fence held in the skill

#### Scenario: Disabled Optional capability is absent

- **GIVEN** an Optional capability that was not enabled during Prep
- **WHEN** the skill draws the Intro C4
- **THEN** that Optional capability MUST NOT appear as reach
- **AND** its capability-specific vendor objects MUST NOT appear as nodes

#### Scenario: Secret Connection detail is named only

- **GIVEN** a locked row with a Connection detail marked secret
- **WHEN** the skill draws the Intro C4
- **THEN** the fence MUST show that detail as a field name
- **AND** it MUST NOT contain a secret value

#### Scenario: Thin row omits a role

- **GIVEN** a locked row whose Typed actions name no vendor scope beyond the
  Identity object
- **WHEN** the skill draws the Intro C4
- **THEN** the reach subgraph MUST be omitted
- **AND** the skill MUST NOT invent a node to fill that role

### Requirement: Lock confirms Integration and path

The project SHALL provide one model-invoked `entro-connect` skill that performs a
Connect run: Lock the exact Integration tile and, when the index lists more than
one Integration path, the chosen path; collect Operator inputs; introduce the
Integration; execute one Operation mode; and write a Connect log. A singleton
Integration path is implicit and MUST NOT create a gate. Lock MUST NOT confirm
`targetSelection`, Setup method, Authentication method, or Optional capabilities.
When `captureRequired` is true on the index entry, Connect MUST request current
connection-form screenshots and stop before Lock.
The skill MUST read the Skill catalog at
`.agents/skills/entro-connect/integrations.json` rather than inventing tiles,
paths, Optional capabilities, Configuration tools, Connection details, Prep
steps, Operator inputs, or Typed actions. It MUST NOT open files under
`documentation/` to perform a Connect run.

#### Scenario: AWS Lock names path

- **GIVEN** the operator connects Amazon Web Services
- **WHEN** Lock completes
- **THEN** the Lock MUST name the Integration tile and the selected Integration path
- **AND** it MUST NOT name Optional capabilities

#### Scenario: Capture-required tile stops early

- **GIVEN** the operator chooses an index entry with `captureRequired: true`
- **WHEN** Orientation completes
- **THEN** Connect MUST request current connection-form screenshots
- **AND** it MUST stop before Lock, Intro, Row catalog loading, and tools

### Requirement: Optional capability consent is just-in-time

When Prep reaches an Optional capability supported by the locked Integration
path, Connect MUST ask whether to enable it immediately before running that
capability's instructions or Typed actions. Optional capabilities MUST NOT be
selected at Lock. Automated Operation mode MUST pause for the same consent.
Bundled scripts that grant nonselective optional permissions MUST disclose every
permission they include and MUST NOT claim selective enforcement the script
cannot perform.

#### Scenario: AWS optional capability during Prep

- **GIVEN** a locked Amazon Web Services path supports Vault management
- **WHEN** Prep reaches the optional vault-observability work
- **THEN** Connect MUST obtain operator consent immediately before that work
- **AND** it MUST skip the instructions and Typed actions when consent is declined

### Requirement: Locked catalog supports Intro

After Lock, the Skill catalog SHALL provide enough path-owned data to introduce
the Integration without reading ingested documentation.

#### Scenario: Skill does not read ingested pages

- **GIVEN** `documentation/` markdown is absent
- **WHEN** the skill Locks GitHub and its GitHub Cloud - New Integration path
- **THEN** it MUST still complete intro, Operation mode, and Connect log from the Skill catalog

#### Scenario: Intro names Connector deployment and needs

- **GIVEN** a completed Lock
- **WHEN** the skill introduces the Integration
- **THEN** it MUST explain the Integration from the row `summary`, name the locked Integration path, name Connector deployment options from skill-local connector markdown, list supported Optional capabilities without selecting them, list required access, Configuration tools with Fit, Prep step titles, Connection details field names, collected Operator inputs, and show the Intro C4
- **AND** it MUST state that no configuration has been performed yet
- **AND** it MUST NOT install or configure a Connector
- **AND** it MUST NOT open `documentation/` pages

### Requirement: Intro is persisted before Operation mode

After Lock the skill SHALL create or append the Connect log, collect Operator inputs
during Intro, persist the same operator-facing Intro brief that was shown in chat,
and only then offer Operation mode. The brief MUST include purpose, the locked
Integration path, supported Optional capabilities, topology, prerequisites,
tools and probe status, names, fields, Prep outline,
safety boundary, and C4.

#### Scenario: Mode is not the first operator choice after Lock

- **GIVEN** a completed Lock
- **WHEN** the skill continues the Connect run
- **THEN** it MUST persist the Intro in the Connect log
- **AND** it MUST NOT offer Operation mode until that Intro exists in the file

### Requirement: Operation mode gates tools and the execution actor

A Connect run SHALL use Operation mode `instructions`, `supervised`, or
`automated`. Automated MUST NOT be offered when every Configuration tool on the
locked Integration path is Fit `none`, and the skill MUST explain why automated
is hidden. A Prep step that carries an Operator-only or an Uncataloged
classification MUST NOT by itself hide automated, because automated covers the
first by operator execution and the second by a Runtime Doc-derived action.
Configuration tool install and auth-once SHALL run only for supervised and automated.
The skill SHALL pick tools from the locked Integration path, preferring Fit
`preferred`, then usable CLI, then MCP. Automated SHALL
execute every cataloged Typed action in the plan itself, each announced
immediately before it runs and without a per-change gate, and SHALL execute an
Uncataloged Prep step itself after a single consent gate on the derived command.
Supervised SHALL
disclose and gate each action and then have the operator execute it, and the
skill MUST NOT execute a mutation in that mode. Instructions (playbook) MUST NOT
execute mutations.

#### Scenario: Incomplete typed-action plan hides automated

- **GIVEN** a locked Integration path whose Prep steps lack a complete Typed action plan
- **AND** every Configuration tool on that path is Fit `none`
- **WHEN** the skill offers Operation mode
- **THEN** the options MUST be instructions and supervised
- **AND** automated MUST NOT be offered

#### Scenario: Fit none hides automated

- **GIVEN** a Lock whose Configuration tools are only Fit `none`
- **WHEN** the skill offers Operation mode
- **THEN** the options MUST be instructions and supervised
- **AND** automated MUST NOT be offered

#### Scenario: Uncataloged step does not hide automated

- **GIVEN** a locked Integration path carrying an Uncataloged Prep step and at least one Configuration tool above Fit `none`
- **WHEN** the skill offers Operation mode
- **THEN** automated MUST be offered

#### Scenario: GitHub Cloud New stays automated

- **GIVEN** the GitHub Cloud - New Lock whose `gh` Fit is `usable`
- **AND** that path carries an Uncataloged Prep step
- **WHEN** the skill offers Operation mode
- **THEN** automated MUST be offered

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

#### Scenario: Automated gates only the uncataloged command

- **GIVEN** a Configuration plan holding both cataloged Typed actions and an Uncataloged Prep step under automated
- **WHEN** the skill works the plan
- **THEN** it MUST announce and run each cataloged Typed action without a gate
- **AND** it MUST take exactly one consent gate for the Uncataloged Prep step's derived command
- **AND** it MUST run the derived command itself once consent is given

#### Scenario: Instructions name an uncataloged step as uncataloged

- **GIVEN** an Uncataloged Prep step on the locked Integration path
- **WHEN** the skill writes the instructions write-up
- **THEN** it MUST name the step as uncataloged
- **AND** it MUST NOT present it as a vendor constraint

### Requirement: Instructions-only batch persists Intro per target

When the operator names several Integrations and wants instructions
only, the skill SHALL Lock each target, persist Intro, and write one Connect log
per target. It MUST NOT require tool install, auth-once, or mutating execution.
Supervised and automated runs MUST stay sequential, one Lock at a time.

#### Scenario: Three instruction playbooks

- **GIVEN** the operator asks for instructions for AWS, Okta, and Slack
- **WHEN** the skill runs
- **THEN** it MUST write three Connect logs
- **AND** each Connect log MUST contain that Integration's persisted Intro
- **AND** it MUST NOT require tool login

#### Scenario: Supervised is sequential

- **GIVEN** the operator asks to supervise AWS and Okta in one message
- **WHEN** the skill runs
- **THEN** it MUST complete one Lock before starting the next

### Requirement: Connect log records evidence without secrets

Each Connect run SHALL write or append a Connect log in the Connect run folder
named `entro-<tile-slug>` with an optional Integration-path slug, gitignored via
`/integrationConfig/`.
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

### Requirement: Configure once runs after failed auth-check

When a locked Configuration tool's Tool install entry includes `configureOnce`,
supervised and automated Connect runs SHALL, after an invalid auth-check and
before requesting any sign-in, run the `check` of every cataloged Authentication
route. When exactly one route matches its `suitableWhen`, the skill MUST select
that route without gating. When no route matches, or two or more match, the
skill MUST gate the choice, listing each route's `name` and `whenToPick` in
catalog order; that gate MUST NOT mark any route as recommended and the skill
MUST NOT rank the routes in prose.

For the selected route the skill MUST request its `command` in the operator's
terminal in every Operation mode, including automated, finish that message with
Continue or Help, and MUST NOT run the command itself, unless that route was
selected because its check was already suitable, in which case the skill MUST
skip the command and go straight to the route's sign-in. That request MUST relay
every prompt of that route with its `whereToFind` statement, in catalog order,
plus the route's `docsUrl`; a request that names only the command MUST be treated
as incomplete. A prompt marked `secret` MUST be relayed by label and source only,
with a statement that the value is typed into the vendor CLI; the skill MUST NOT
ask for it, accept it, or echo it. The skill MUST NOT invent prompt guidance that
the catalog does not carry, MUST NOT relay prompts from a route it did not
select, MUST NOT collect answers as Operator inputs, and MUST NOT write them to
the Connect log, which records only the selected route's `name`, that Configure
once was requested, and its outcome.

After Continue the skill SHALL re-run auth-check. A valid session MUST skip
sign-in and record Platform identity. When the session is still invalid and the
selected route's `authOnce` is non-null, the skill MUST request that value — not
the entry-level `authOnce` and not another route's. When the selected route's
`authOnce` is null, the skill MUST NOT request any sign-in and MUST instead
re-request that route's `command` or offer Help. Help MUST collect non-secret
error output and return to Continue or Help. When the picked tool has no
`configureOnce` but another locked Configuration tool has the same
`authCheck.command` and a `configureOnce` object, the skill MUST use that
object, including all of its routes (prefer `aws` when several match). When no
`configureOnce` applies, the skill MUST keep today's auth-check then `authOnce`
path.

#### Scenario: No credentials at all gates the route choice

- **GIVEN** Operation mode is supervised or automated
- **AND** the catalog auth-check reports no valid session
- **AND** no Authentication route matches its `suitableWhen`
- **WHEN** the skill reaches the tools step
- **THEN** it MUST present the routes with their `name` and `whenToPick` in catalog order
- **AND** it MUST NOT mark any route as recommended

#### Scenario: Missing SSO config requests the wizard

- **GIVEN** no Authentication route matches its `suitableWhen`
- **AND** the operator picked the IAM Identity Center route at the gate
- **WHEN** the skill continues the tools step
- **THEN** it MUST request `aws configure sso` in the operator's terminal
- **AND** it MUST NOT run the wizard itself

#### Scenario: Existing SSO profile skips the wizard

- **GIVEN** the catalog auth-check reports no valid session
- **AND** only the IAM Identity Center route matches its `suitableWhen`
- **WHEN** the skill reaches the tools step
- **THEN** it MUST NOT gate the route choice
- **AND** it MUST NOT request `aws configure sso`
- **AND** it MUST request that route's `authOnce` in the operator's terminal

#### Scenario: Two suitable routes gate the choice

- **GIVEN** the catalog auth-check reports no valid session
- **AND** both the access keys route and the Identity Center route match their `suitableWhen`
- **WHEN** the skill reaches the tools step
- **THEN** it MUST gate the route choice before requesting anything

#### Scenario: The request names where each value comes from

- **GIVEN** the operator selected a route whose check was unsuitable
- **WHEN** the skill writes the Configure once request
- **THEN** it MUST list every prompt of that route with its `whereToFind` statement in catalog order
- **AND** it MUST include that route's `docsUrl`
- **AND** it MUST NOT relay prompts belonging to another route

#### Scenario: A secret prompt is never collected

- **GIVEN** the selected route has a prompt marked `secret`
- **WHEN** the skill relays that prompt
- **THEN** it MUST give the label and `whereToFind` and state the value is typed into the vendor CLI
- **AND** it MUST NOT ask the operator for that value in chat
- **AND** the Connect log MUST NOT contain it

#### Scenario: A route without sign-in never requests a login

- **GIVEN** the operator selected the IAM user access keys route
- **AND** that route's `authOnce` is null
- **AND** the auth-check is still invalid after Continue
- **WHEN** the skill continues the tools step
- **THEN** it MUST NOT request `aws sso login`
- **AND** it MUST re-request that route's `command` or offer Help

#### Scenario: Wizard that already signed in skips login

- **GIVEN** the operator completed the selected route's command
- **AND** the catalog auth-check now reports a valid session
- **WHEN** the skill continues the tools step
- **THEN** it MUST skip sign-in
- **AND** it MUST record Platform identity

#### Scenario: Wizard answers stay out of chat and the log

- **GIVEN** the operator is answering the selected route's command
- **WHEN** the skill records the tools step
- **THEN** it MUST NOT collect those answers as Operator inputs
- **AND** the Connect log MUST record only the selected route's `name`, that Configure once was requested, and its outcome

#### Scenario: Terraform uses the AWS Configure once object

- **GIVEN** the Lock lists `aws` and `terraform` as Configuration tools
- **AND** the picked tool is `terraform`
- **AND** `terraform` omits `configureOnce`
- **AND** `aws` has `configureOnce` and the same `authCheck.command`
- **WHEN** the terraform auth-check reports no valid session
- **THEN** the skill MUST use the `aws` Configure once object
- **AND** it MUST offer the same routes and relay the selected route's prompts

### Requirement: Auth-once is checked then confirmed

For supervised and automated modes the skill SHALL run the catalog auth-check
and Platform identity query before requesting login. A valid session MUST skip
Configure once and login and gate continue-with-this-environment versus
re-authenticate or help. An invalid session MUST follow Configure once when the
catalog provides it, then request the catalog `authOnce` in the operator's
terminal only if auth-check is still invalid, in automated mode as well as
supervised, and finish that message with Continue (check authentication) or Help
(authentication issues). Help MUST collect non-secret error output, diagnose it,
and return to that gate. The skill MUST NOT accept a login secret into session
and MUST NOT run `authOnce` or Configure once itself.

#### Scenario: Valid session skips login

- **GIVEN** the catalog auth-check reports an authenticated session
- **WHEN** the skill records Platform identity
- **THEN** it MUST skip Configure once
- **AND** it MUST skip a new login
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
- **AND** Configure once does not apply or already succeeded
- **WHEN** the skill still has no valid session
- **THEN** it MUST request the catalog `authOnce` in the operator's terminal
- **AND** it MUST NOT run the login itself

---

### Requirement: Connect loads the Skill catalog progressively

The `entro-connect` skill SHALL read the Skill catalog index for Orientation and
Lock. It MUST NOT open a Row catalog, `tool-install.json`, or any Skill-held
artifact until Lock is stated. A `captureRequired` index entry MUST stop before
those reads. After Lock it SHALL open only the locked Integration's `catalogPath`.
For supervised and automated it SHALL read Tool install file entries keyed by the
locked Integration path's Configuration tools and enabled Optional capabilities
only. It MUST NOT open `documentation/` markdown to perform a Connect run. It MUST
remain one skill: row folders MUST NOT contain a `SKILL.md`.

_Rationale: ADR-0002 (apply)_

#### Scenario: Tile row drives progressive loading

- **GIVEN** the operator chooses an Integration tile during Orientation
- **WHEN** the skill prepares Lock
- **THEN** it MUST use that tile's thin index row and `integrationPathNames`
- **AND** it MUST NOT open the Row catalog before Lock is stated

#### Scenario: Row catalog opens after Lock only

- **GIVEN** a completed Lock of GitHub and its GitHub Cloud - New path
- **WHEN** the skill continues the Connect run
- **THEN** it MUST open `catalogPath` for that Integration only
- **AND** it MUST NOT open another Integration's `catalog.json`

#### Scenario: Tool install file waits for tools

- **GIVEN** Orientation and Lock are in progress
- **WHEN** the skill reads catalog data
- **THEN** it MUST NOT read `tool-install.json`
- **AND** after Lock, tools.md MUST read only the locked Configuration tool keys from that file

#### Scenario: Skill does not read ingested pages

- **GIVEN** `documentation/` markdown is absent
- **WHEN** the skill Locks GitHub and its GitHub Cloud - New path
- **THEN** it MUST still complete intro, Operation mode, and Connect log from the Skill catalog tree

