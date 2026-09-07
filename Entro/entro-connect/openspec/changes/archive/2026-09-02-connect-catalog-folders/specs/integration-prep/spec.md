<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## MODIFIED Requirements

### Requirement: Connect executes Skill-held files only

When a Typed action names a Skill-held onboarding artifact, entro-connect SHALL
SHA-256 the skill-local file at `script.skillPath` before the Approve gate and
SHALL execute that path after Approve. `skillPath` MUST be skill-root-relative
under the owning row folder. It MUST NOT download from GitBook at Connect time.
It MUST NOT resolve Skill-held files under `vendor/`. Checksum mismatch MUST
stop the Configuration plan. Disclosure MUST include path, byte size, and
checksum, not the file body. Secret-producing actions, including a script that
prints a Client Secret, MUST stay operator-executed; the Connect log MUST record
identifiers only.

#### Scenario: Local checksum matches before Approve

- **GIVEN** a Typed action with `script.skillPath` and a `sha256:` checksum of 64 hex digits
- **AND** the skill-local file hashes to that checksum
- **WHEN** the skill reaches that action
- **THEN** it MUST disclose path, size, and checksum
- **AND** it MUST NOT fetch `originUrl` or any GitBook URL
- **AND** `skillPath` MUST NOT begin with `vendor/`

#### Scenario: Local checksum mismatch stops the plan

- **GIVEN** a Typed action whose skill-local file does not match `script.checksum`
- **WHEN** the skill would disclose that action
- **THEN** it MUST stop
- **AND** it MUST NOT execute the mutation

#### Scenario: Client Secret stays with the operator

- **GIVEN** Azure onboarding script output includes a Client Secret
- **WHEN** the operator or automated mutation has run
- **THEN** the Connect log MUST record Client ID and Tenant ID only
- **AND** the Connect log MUST NOT record the Client Secret

#### Scenario: Azure script lives in the Microsoft Ecosystem row folder

- **GIVEN** a Typed action whose Skill-held artifact is Entro's Azure onboarding script
- **WHEN** ingest has written the Skill catalog
- **THEN** `skillPath` MUST be under `integrations/microsoft-ecosystem/`
- **AND** prep MUST resolve that path under the skill folder
