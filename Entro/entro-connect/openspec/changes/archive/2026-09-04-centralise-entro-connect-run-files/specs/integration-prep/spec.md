<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

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

---

## MODIFIED Requirements

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
