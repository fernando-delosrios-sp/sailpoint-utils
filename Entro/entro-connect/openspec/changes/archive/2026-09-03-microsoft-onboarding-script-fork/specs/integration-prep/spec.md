## ADDED Requirements

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
- **THEN** it MUST route the command output to a Secret sink outside the repository and both skill trees
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

---

## REMOVED Requirements

---

## RENAMED Requirements
