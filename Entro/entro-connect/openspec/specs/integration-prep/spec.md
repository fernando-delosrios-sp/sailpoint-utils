# integration-prep

## Purpose

What the customer must configure on each Integration target before Entro can connect.
## Requirements
### Requirement: Disposable Connect files live in the Connect run folder

The skill SHALL create every Temporary script copy and every Secret sink inside
the Connect run folder. Temporary script copies MUST use a `tmp-` filename
prefix. Secret sinks MUST use a `sink-` filename prefix. The skill MUST NOT
write those files into either Skill catalog tree, over `script.skillPath`, or
into the operator's operating-system temp directory as their home.

#### Scenario: Temporary script copy is in the Connect run folder

- **GIVEN** the operator Approved a new target name for a pinned script
- **WHEN** the skill prepares a Temporary script copy
- **THEN** that file MUST live in the Connect run folder
- **AND** its name MUST begin with `tmp-`
- **AND** it MUST NOT overwrite `script.skillPath`

#### Scenario: Secret sink is in the Connect run folder

- **GIVEN** Operation mode is automated
- **AND** a Typed action is `secretProducing`
- **WHEN** the skill runs that command
- **THEN** the Secret sink MUST live in the Connect run folder
- **AND** its name MUST begin with `sink-`
- **AND** the Connect log MUST NOT record the Secret sink path

### Requirement: Connect executes Skill-held files only

When a Typed action names a Skill-held onboarding artifact, entro-connect SHALL
SHA-256 the skill-local file at `script.skillPath` before it announces or gates
that action. `skillPath` MUST be skill-root-relative under the owning row
folder. It MUST NOT download from GitBook at Connect time. It MUST NOT resolve
Skill-held files under `vendor/`. Checksum mismatch MUST stop the Configuration
plan. Disclosure MUST include path, byte size, checksum, and the exact command
that will run, not the file body. In automated Operation mode the skill SHALL
run the command itself, or a Temporary script copy when a gated fix requires it,
whether or not the action is secret-producing. In supervised Operation mode the
operator SHALL run it after Approve. It MUST NOT write the Skill-held file.
A secret the command produces, including a Client Secret, MUST NOT reach agent
context, chat, or the Connect log; the Connect log and chat MUST record
identifiers only. For a Local onboarding fork, `script.checksum` MUST be the
Skill-held fork bytes; Connect MUST NOT compare them to `originChecksum` and
MUST NOT ask remote versus local.

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
- **WHEN** the mutation has run in either Operation mode
- **THEN** the Client Secret MUST reach only the operator's vault, through their own terminal under supervised or through a Secret sink under automated
- **AND** the Connect log MUST record Client ID and Tenant ID only
- **AND** the Connect log MUST NOT record the Client Secret
- **AND** chat MUST NOT record the Client Secret

#### Scenario: Azure script lives in the Microsoft Ecosystem row folder

- **GIVEN** a Typed action whose Skill-held artifact is Entro's Azure onboarding script
- **WHEN** ingest has written the Skill catalog
- **THEN** `skillPath` MUST be under `integrations/microsoft-ecosystem/`
- **AND** prep MUST resolve that path under the skill folder

#### Scenario: Supervised runs the approved script

- **GIVEN** Operation mode is supervised
- **AND** the operator Approved a Typed action with a pinned script
- **WHEN** the skill continues Prep
- **THEN** it MUST give the operator the exact command to run in their own terminal
- **AND** it MUST NOT execute that mutation itself
- **AND** it MUST verify the non-secret result the operator reports

#### Scenario: Automated runs the approved script

- **GIVEN** Operation mode is automated
- **AND** the next Typed action carries a pinned script
- **WHEN** the skill continues Prep
- **THEN** it MUST state that it is running that command now, before running it
- **AND** it MUST run the disclosed command or Temporary script copy itself
- **AND** it MUST NOT ask the operator to run it
- **AND** it MUST NOT wait for a per-change Approve

#### Scenario: Automated runs a secret-producing script through a Secret sink

- **GIVEN** Operation mode is automated
- **AND** the Typed action is `secretProducing`
- **WHEN** the skill runs that command
- **THEN** it MUST route the command output to a Secret sink in the Connect run folder
- **AND** it MUST read back only named non-secret identifiers from that file
- **AND** it MUST tell the operator the Secret sink path so they can vault the secret
- **AND** it MUST delete the Secret sink once the operator confirms the secret is vaulted
- **AND** it MUST NOT write the Secret sink path to the Connect log

#### Scenario: A secret that cannot be withheld is handed back

- **GIVEN** Operation mode is automated
- **AND** a secret-producing command cannot withhold the secret from its terminal output
- **WHEN** the skill reaches that action
- **THEN** it MUST NOT run that command
- **AND** it MUST state why and hand that one step to the operator

#### Scenario: Connect uses the fork checksum not origin

- **GIVEN** the Microsoft Automated PowerShell pin is a Local onboarding fork
- **AND** `originChecksum` differs from `checksum`
- **WHEN** the skill reaches that Typed action
- **THEN** it MUST verify the Skill-held file against `checksum`
- **AND** it MUST NOT fetch the Anonymous origin URL
- **AND** it MUST NOT ask the Connect operator to choose remote or local

### Requirement: Microsoft Automated PowerShell grants the Entro permission-audit set

The Microsoft Ecosystem Automated PowerShell Local onboarding fork SHALL assign
the Entro permission-audit Graph and Defender application permissions on
create-app and as the default selection of the API-permissions menu. That set
MUST come from ingested Azure permissions-reference pages, plus the documented
gap `Application.ReadWrite.All` and Graph `Device.Read.All`. Teams Bot grants
MUST use `TeamsAppInstallation.ReadWriteSelfForUser.All` and MUST NOT use
`TeamsAppInstallation.ReadWriteForChat.All` as a substitute. The Typed action
`expectedChange` for running that script MUST state that those grants exist on
the Identity object. Durable permission and Az.Resources patches MUST live in
the Local onboarding fork, not in a Temporary script copy.

#### Scenario: Create-app grants the audit permission set

- **GIVEN** the operator runs create-app on the Local onboarding fork
- **WHEN** the app registration is created
- **THEN** the script MUST request the Entro permission-audit Graph and Defender permissions
- **AND** it MUST NOT stop at Mandatory plus Azure Cloud only

#### Scenario: API-permissions menu defaults to the full audit set

- **GIVEN** the operator opens the script's API-permissions menu
- **WHEN** the selection list is shown
- **THEN** every audit permission group MUST be selected by default
- **AND** Mandatory MUST remain always enabled

#### Scenario: Teams Bot names match documentation

- **GIVEN** the Local onboarding fork lists Teams native-messaging permissions
- **WHEN** those names are read from the Skill-held script
- **THEN** they MUST include `TeamsAppInstallation.ReadWriteSelfForUser.All`
- **AND** they MUST NOT substitute `TeamsAppInstallation.ReadWriteForChat.All` for that grant

#### Scenario: Typed action expectedChange names the audit grants

- **GIVEN** the Microsoft Ecosystem Automated PowerShell Typed action that runs the onboarding script
- **WHEN** ingest has written the Row catalog
- **THEN** `expectedChange` MUST require Entro permission-audit Graph and Defender grants on the Identity object

#### Scenario: Durable patches are not a Temporary script copy

- **GIVEN** Az.Resources role-definition shape or the audit permission set must persist across Connect runs
- **WHEN** the project records those edits
- **THEN** they MUST be in the Local onboarding fork at `script.skillPath`
- **AND** they MUST NOT be only a Temporary script copy

### Requirement: Uncataloged Prep steps are executed, not handed over

A Prep step carrying neither a Typed action nor an authored Operator-only
`reason` SHALL be classified as an Uncataloged Prep step. Under Operation mode
`automated` the skill SHALL derive a Runtime Doc-derived action for that step
from the vendor's documentation, disclose the exact command together with the
documentation source it came from, obtain consent once, then execute and verify
it as the execution actor. The skill MUST derive the mutation from vendor
documentation and MUST NOT compose a command the vendor does not document. When
vendor documentation yields no command for the step, the skill SHALL record that
absence and have the operator execute it.

#### Scenario: Automated derives and runs an uncataloged step

- **GIVEN** an Uncataloged Prep step on the locked Integration path under automated
- **AND** the picked Configuration tool has a recorded Platform identity
- **WHEN** the skill reaches that step
- **THEN** it MUST disclose the derived command and the documentation source it came from
- **AND** it MUST obtain consent once before running it
- **AND** it MUST execute and verify the command itself
- **AND** the Connect log MUST record the agent as the execution actor

#### Scenario: Operator declines the derived command

- **GIVEN** an Uncataloged Prep step whose derived command has been disclosed under automated
- **WHEN** the operator declines at the consent gate
- **THEN** the operator MUST execute the step
- **AND** the Connect log MUST record the decline for that run
- **AND** the catalog classification MUST remain unchanged

#### Scenario: Vendor documents no command for the step

- **GIVEN** an Uncataloged Prep step under automated
- **WHEN** vendor documentation yields no command covering it
- **THEN** the skill MUST NOT compose a command from any other source
- **AND** the operator MUST execute the step
- **AND** the Connect log MUST record the absent documentation as the reason

#### Scenario: Derived action that mints a credential uses the Secret sink

- **GIVEN** an Uncataloged Prep step whose derived command produces a secret under automated
- **WHEN** the skill runs that command after consent
- **THEN** the output MUST go to a Secret sink in the Connect run folder
- **AND** the Connect log MUST record non-secret identifiers only
- **AND** the skill MUST NOT classify the step as an Operator-only step

#### Scenario: Supervised discloses the derived command

- **GIVEN** an Uncataloged Prep step under supervised
- **WHEN** the skill reaches that step
- **THEN** it MUST disclose the derived command and its documentation source
- **AND** the operator MUST execute it
- **AND** the skill MUST NOT run the mutation

### Requirement: Operator-only steps are disclosed without mutation

An Operator-only Prep step SHALL be disclosed with its `reason` and `evidence`.
The skill MUST NOT mutate the target for that step in any Operation mode. The
operator reports evidence back. An authored `reason` SHALL be necessary for this
classification: absence of a Typed action alone MUST be treated as an
Uncataloged Prep step, not as an Operator-only step.

#### Scenario: UI-only step is operator-executed

- **GIVEN** a Prep step classified Operator-only because the platform exposes it only through its UI
- **WHEN** the skill reaches that step
- **THEN** it MUST state the reason and the evidence to collect
- **AND** it MUST NOT run a mutation command

#### Scenario: Merge-sensitive step stays operator-executed under automated

- **GIVEN** a Prep step whose authored `reason` records that its documented command route replaces a shared policy
- **WHEN** the skill reaches that step under automated
- **THEN** it MUST state the reason and the evidence to collect
- **AND** it MUST NOT derive a command for that step
- **AND** the operator MUST execute it

#### Scenario: Missing reason is not an Operator-only step

- **GIVEN** a Prep step with no Typed action and no authored `reason`
- **WHEN** the skill classifies that step
- **THEN** it MUST treat the step as an Uncataloged Prep step
- **AND** it MUST NOT present the absence of a Typed action to the operator as a vendor constraint

### Requirement: Per-integration preparation is explicit

For each supported Integration, the project SHALL record the preparation steps Entro
requires on the vendor system (identities, apps, roles, scopes, network, or
equivalent) as curated Prep steps on its Integration paths. Fit `preferred` paths
SHALL also record Typed actions for those steps.

#### Scenario: Operator follows integration prep

- **GIVEN** an Integration that appears in Entro's onboarding catalog and has ingested documentation
- **WHEN** an operator (or later skill) needs to prepare that Integration
- **THEN** they MUST be able to follow a complete, ordered list of target-side steps without inventing requirements Entro does not document
- **AND** that list MUST be the locked Integration path's `prepSteps`

### Requirement: Prep is separated from Entro form fill

Integration prep instructions SHALL describe only work done on the Integration target, not the
fields typed into Entro.

#### Scenario: Boundary with connection details

- **GIVEN** an Integration onboarding guide
- **WHEN** a step creates a credential or identifier on the target
- **THEN** that creation step belongs in integration-prep, and which Entro field receives the value belongs in connection-details

### Requirement: Prep resolves from locked Integration path

Integration prep SHALL use only the locked Integration path's ordered `prepSteps`
and Typed actions. When an Integration declares paths, row-level prep MUST NOT
exist and prep from another path on the same tile MUST NOT be merged. Optional
capability prep steps and Typed actions MUST run only after just-in-time operator
consent, including in automated Operation mode. A later skill MUST NOT invent
steps Entro does not catalog. Each step's `instruction` SHALL be sufficient
without opening ingested pages.

#### Scenario: Path-owned prep

- **GIVEN** a locked GitHub Integration path GitHub Cloud - New
- **WHEN** an operator or skill performs Integration prep
- **THEN** they MUST follow that path's list in order
- **AND** they MUST NOT mix steps from another path on the GitHub tile

### Requirement: Optional capability prep requires consent

Optional capability prep and Typed actions MUST run only after just-in-time
operator consent, including in automated Operation mode.

#### Scenario: Optional capability prep waits for consent

- **GIVEN** a locked path supports an Optional capability with additional Prep steps
- **WHEN** Prep reaches that capability
- **THEN** the skill MUST obtain operator consent immediately before its work
- **AND** it MUST skip those Prep steps and Typed actions when consent is declined

### Requirement: Prep evidence is non-secret

Prep evidence SHALL record only non-secret observable results in the Connect log.

#### Scenario: Evidence is non-secret

- **GIVEN** a Prep step with an `evidence` bound
- **WHEN** supervised or automated mode records the step
- **THEN** the Connect log MUST record that evidence
- **AND** the Connect log MUST NOT record a secret value

### Requirement: Configuration plan is disclosed before mutation

After Operator inputs and Operation mode are settled, the skill SHALL persist a
Configuration plan: the ordered Typed actions, tools, targets, expected changes,
evidence checks, and rollback or irreversible-impact notes. Intro MUST remain a
capabilities outline with a no-action-yet boundary. Before each mutating action
the skill SHALL disclose the exact change and run vendor preview when the
catalog says it is supported. In supervised Operation mode it SHALL then gate
Approve, adjust (Operator inputs or remaining Operation mode), or stop, and the
operator SHALL execute the approved mutation. In automated Operation mode the
skill SHALL state that it is running the change now and then execute it, with no
per-change gate, whether or not the action is secret-producing. Catalog Typed
action definitions MUST NOT be rewritten at run time. A Temporary script copy MAY
bind names or skip an interactive menu for one run. Playbook MUST NOT execute any
mutation.

#### Scenario: Plan exists before the first mutation

- **GIVEN** the operator has chosen supervised or automated
- **WHEN** the skill is about to perform Integration prep
- **THEN** the Connect log MUST already contain the Configuration plan
- **AND** no Typed action mutation MUST have been executed yet

#### Scenario: Each mutating action is approved

- **GIVEN** the next Typed action would change the target platform
- **WHEN** the skill reaches that action
- **THEN** it MUST disclose the command or pinned script, target, expected change, and reversal or impact
- **AND** that disclosure MUST precede any execution of the action

#### Scenario: Supervised waits for Approve then the operator executes

- **GIVEN** Operation mode is supervised
- **WHEN** the skill reaches a mutating Typed action
- **THEN** it MUST wait for Approve, adjust, or stop
- **AND** the operator MUST execute the approved mutation
- **AND** the skill MUST NOT execute the mutation itself

#### Scenario: Automated executes without a per-change gate

- **GIVEN** Operation mode is automated
- **WHEN** the skill reaches a mutating Typed action in the persisted plan
- **THEN** it MUST announce the change and execute it
- **AND** it MUST NOT open an Approve gate for that change
- **AND** it MUST NOT hand the command to the operator

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

### Requirement: Replace or collision retries through a gated fix

When a Typed action would replace or collide with an existing object on the
destination platform, the skill SHALL stop before overwriting, disclose the
existing object, propose a fix (another name or equivalent configuration), and
gate Approve, adjust, or stop. This gate applies in automated Operation mode as
well, which MUST interrupt itself rather than overwrite. After Approve of the fix
it SHALL run again, using a Temporary script copy in the Connect run folder when
the pinned script hardcodes the name. It MUST NOT apply the fix without that gate.

#### Scenario: Script would replace an existing app

- **GIVEN** a pinned onboarding script that creates an app named in the script
- **AND** that name already exists on the destination
- **WHEN** the skill would run or continue that mutation
- **THEN** it MUST disclose the existing object and a proposed fix
- **AND** it MUST wait for Approve, adjust, or stop
- **AND** it MUST NOT replace the existing object until the operator Approves a fix

#### Scenario: Automated pauses for a collision

- **GIVEN** Operation mode is automated
- **AND** the next Typed action would collide with an existing object
- **WHEN** the skill reaches that action
- **THEN** it MUST stop before overwriting and gate the proposed fix
- **AND** it MUST NOT treat the mode choice as approval of that fix

#### Scenario: Approved fix re-runs via Temporary script copy

- **GIVEN** the operator Approved a new target name for a pinned script
- **WHEN** the skill retries the mutation
- **THEN** it MUST checksum the Skill-held file first
- **AND** it MUST prepare a Temporary script copy with that name in the Connect run folder
- **AND** the execution actor MUST follow the Operation mode, the agent under automated and the operator under supervised
- **AND** it MUST NOT write `script.skillPath`

### Requirement: Interactive scripts become unattended or stop

When a Skill-held script requires an interactive menu, the skill SHALL attempt a
Temporary script copy that binds the chosen path so the run can complete without
prompts. In automated Operation mode the skill SHALL run that copy; in
supervised Operation mode the operator SHALL run it. If that binding is not
possible, it MUST stop that Prep step and have the operator run the original
pinned file. It MUST NOT guess menu answers in chat.

#### Scenario: Menu cannot be bound unattended

- **GIVEN** a pinned script that prompts for menu choices
- **AND** the skill cannot bind those choices on a Temporary script copy
- **WHEN** the skill reaches that action
- **THEN** it MUST stop that step
- **AND** it MUST tell the operator to run the original Skill-held file
- **AND** it MUST NOT invent menu responses

### Requirement: Failed verification stops the plan

When verification after a Typed action mutation fails, the skill SHALL stop,
persist observed state, and gate a cataloged rollback when one exists, retry
verification, or diagnosis/help. It MUST NOT continue with later independent
actions in the same Configuration plan.

#### Scenario: Verification fail after mutation

- **GIVEN** a Typed action mutation has run and verification does not match the expected change
- **WHEN** the skill records the failure
- **THEN** it MUST stop the Configuration plan
- **AND** it MUST persist observed non-secret state
- **AND** it MUST NOT execute the next mutating action

---

