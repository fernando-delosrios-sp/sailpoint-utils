## MODIFIED Requirements

### Requirement: Connect executes Skill-held files only

When a Typed action names a Skill-held onboarding artifact, entro-connect SHALL
SHA-256 the skill-local file at `script.skillPath` before the Approve gate.
`skillPath` MUST be skill-root-relative under the owning row folder. It MUST NOT
download from GitBook at Connect time. It MUST NOT resolve Skill-held files
under `vendor/`. Checksum mismatch MUST stop the Configuration plan. Disclosure
MUST include path, byte size, checksum, and the exact command that will run, not
the file body. After Approve, in supervised and automated Operation modes, the
skill SHALL run a non-secret-producing command, or a Temporary script copy when
a gated fix requires it. It MUST NOT write the Skill-held file.
Secret-producing actions, including a script that prints a Client Secret, MUST
stay operator-executed; the Connect log and chat MUST record identifiers only.

#### Scenario: Local checksum matches before Approve

- **GIVEN** a Typed action with `script.skillPath` and a `sha256:` checksum of 64 hex digits
- **AND** the skill-local file hashes to that checksum
- **WHEN** the skill reaches that action
- **THEN** it MUST disclose path, size, checksum, and the exact command
- **AND** it MUST NOT fetch `originUrl` or any GitBook URL
- **AND** `skillPath` MUST NOT begin with `vendor/`

#### Scenario: Local checksum mismatch stops the plan

- **GIVEN** a Typed action whose skill-local file does not match `script.checksum`
- **WHEN** the skill would disclose that action
- **THEN** it MUST stop
- **AND** it MUST NOT execute the mutation
- **AND** it MUST NOT create a Temporary script copy

#### Scenario: Client Secret stays with the operator

- **GIVEN** Azure onboarding script output includes a Client Secret
- **WHEN** the operator has run the approved mutation
- **THEN** the Connect log MUST record Client ID and Tenant ID only
- **AND** the Connect log MUST NOT record the Client Secret
- **AND** chat MUST NOT record the Client Secret

#### Scenario: Azure script lives in the Microsoft Ecosystem row folder

- **GIVEN** a Typed action whose Skill-held artifact is Entro's Azure onboarding script
- **WHEN** ingest has written the Skill catalog
- **THEN** `skillPath` MUST be under `integrations/microsoft-ecosystem/`
- **AND** prep MUST resolve that path under the skill folder

#### Scenario: Supervised runs the approved script

- **GIVEN** Operation mode is supervised
- **AND** the operator Approved a non-secret-producing Typed action with a pinned script
- **WHEN** the skill continues Prep
- **THEN** it MUST run the disclosed non-secret-producing command or Temporary script copy
- **AND** it MUST NOT wait for the operator to type the command

#### Scenario: Automated runs the approved script

- **GIVEN** Operation mode is automated
- **AND** the operator Approved a non-secret-producing Typed action with a pinned script
- **WHEN** the skill continues Prep
- **THEN** it MUST run the disclosed non-secret-producing command or Temporary script copy

### Requirement: Configuration plan is disclosed before mutation

After Operator inputs and Operation mode are settled, the skill SHALL persist a
Configuration plan: the ordered Typed actions, tools, targets, expected changes,
evidence checks, and rollback or irreversible-impact notes. Intro MUST remain a
capabilities outline with a no-action-yet boundary. Before each mutating action
the skill SHALL disclose the exact change, run vendor preview when the catalog
says it is supported, and gate Approve, adjust (Operator inputs or remaining
Operation mode), or stop. Catalog Typed action definitions MUST NOT be rewritten
at run time. A Temporary script copy MAY bind names or skip an interactive menu
for one run after a gated fix. After Approve, supervised and automated SHALL
execute the disclosed non-secret-producing mutation. Secret-producing mutations
SHALL stay operator-executed. Playbook MUST NOT execute any mutation.

#### Scenario: Plan exists before the first mutation

- **GIVEN** the operator has chosen supervised or automated
- **WHEN** the skill is about to perform Integration prep
- **THEN** the Connect log MUST already contain the Configuration plan
- **AND** no Typed action mutation MUST have been executed yet

#### Scenario: Each mutating action is approved

- **GIVEN** the next Typed action would change the target platform
- **WHEN** the skill reaches that action
- **THEN** it MUST disclose the command or pinned script, target, expected change, and reversal or impact
- **AND** it MUST wait for Approve, adjust, or stop
- **AND** it MUST NOT execute the mutation before Approve

#### Scenario: Playbook does not run mutations

- **GIVEN** Operation mode is playbook (instructions)
- **WHEN** the skill writes the Configuration plan
- **THEN** it MUST NOT execute a Typed action mutation

### Requirement: Name collision is inspected before create

When a collected Operator input names an object that already exists on the
target platform, the skill SHALL safely inspect that object, disclose whether it
matches the expected shape, and gate reuse, choose another name, or stop.
It MUST NOT create a duplicate without that gate.

#### Scenario: Existing app display name

- **GIVEN** the operator chose a display name that already exists on the platform
- **WHEN** the skill would create that object
- **THEN** it MUST inspect and disclose the existing object
- **AND** it MUST NOT create a second object until the operator chooses reuse, another name, or stop

## ADDED Requirements

### Requirement: Replace or collision retries through a gated fix

When a Typed action would replace or collide with an existing object on the
destination platform, the skill SHALL stop before overwriting, disclose the
existing object, propose a fix (another name or equivalent configuration), and
gate Approve, adjust, or stop. After Approve of the fix it SHALL run again,
using a Temporary script copy when the pinned script hardcodes the name. It
MUST NOT apply the fix without that gate.

#### Scenario: Script would replace an existing app

- **GIVEN** a pinned onboarding script that creates an app named in the script
- **AND** that name already exists on the destination
- **WHEN** the skill would run or continue that mutation
- **THEN** it MUST disclose the existing object and a proposed fix
- **AND** it MUST wait for Approve, adjust, or stop
- **AND** it MUST NOT replace the existing object until the operator Approves a fix

#### Scenario: Approved fix re-runs via Temporary script copy

- **GIVEN** the operator Approved a new target name for a pinned script
- **WHEN** the skill retries the mutation
- **THEN** it MUST checksum the Skill-held file first
- **AND** it MUST prepare a Temporary script copy with that name
- **AND** the execution actor MUST follow the action's `secretProducing` boundary
- **AND** it MUST NOT write `script.skillPath`

### Requirement: Interactive scripts become unattended or stop

When a Skill-held script requires an interactive menu, the skill SHALL attempt a
Temporary script copy that binds the chosen path so the run can complete without
prompts. The skill SHALL run that copy only when the action is
non-secret-producing; the operator SHALL run it when the action is
secret-producing. If that binding is not possible, it MUST stop that Prep step
and have the operator run the original pinned file. It MUST NOT guess menu
answers in chat.

#### Scenario: Menu cannot be bound unattended

- **GIVEN** a pinned script that prompts for menu choices
- **AND** the skill cannot bind those choices on a Temporary script copy
- **WHEN** the skill reaches that action after Approve
- **THEN** it MUST stop that step
- **AND** it MUST tell the operator to run the original Skill-held file
- **AND** it MUST NOT invent menu responses
