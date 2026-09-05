## ADDED Requirements

### Requirement: Connect executes Skill-held files only

When a Typed action names a Skill-held onboarding artifact, entro-connect SHALL
SHA-256 the skill-local file at `script.skillPath` before the Approve gate and
SHALL execute that path after Approve. It MUST NOT download from GitBook at
Connect time. Checksum mismatch MUST stop the Configuration plan. Disclosure
MUST include path, byte size, and checksum, not the file body. Secret-producing
actions, including a script that prints a Client Secret, MUST stay
operator-executed; the Connect log MUST record identifiers only.

#### Scenario: Local checksum matches before Approve

- **GIVEN** a Typed action with `script.skillPath` and a `sha256:` checksum of 64 hex digits
- **AND** the skill-local file hashes to that checksum
- **WHEN** the skill reaches that action
- **THEN** it MUST disclose path, size, and checksum
- **AND** it MUST NOT fetch `originUrl` or any GitBook URL

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

### Requirement: Operator-only steps are disclosed without mutation

An Operator-only Prep step SHALL be disclosed with its `reason` and `evidence`.
The skill MUST NOT mutate the target for that step. The operator reports
evidence back. Absence of a Typed action on that step MUST be treated as this
classification, not as an incomplete catalog row once `reason` is present.

#### Scenario: UI-only step is operator-executed

- **GIVEN** a Prep step classified Operator-only because the platform exposes it only through its UI
- **WHEN** the skill reaches that step
- **THEN** it MUST state the reason and the evidence to collect
- **AND** it MUST NOT run a mutation command

---

## MODIFIED Requirements

### Requirement: Per-integration preparation is explicit

For each supported Integration, the project SHALL record the preparation steps Entro
requires on that target (identities, apps, roles, scopes, network, or equivalent)
as curated Prep steps on the Integration index. Every Prep step SHALL have a
Typed action (Skill-held artifact or Doc-derived) or an Operator-only
classification with reason and evidence. Fit `preferred` paths SHALL NOT remain
preferred while any selected Prep step is silent.

#### Scenario: Operator follows integration prep

- **GIVEN** an Integration that appears in Entro's onboarding catalog and has ingested documentation
- **WHEN** an operator (or later skill) needs to prepare that Integration
- **THEN** they MUST be able to follow a complete, ordered list of target-side steps without inventing requirements Entro does not document
- **AND** that list MUST be the index `prepSteps` for the Lock
- **AND** each step MUST carry a Typed action or an Operator-only classification

### Requirement: Prep is separated from Entro form fill

Integration prep instructions SHALL describe only work done on the Integration target, not the
fields typed into Entro.

#### Scenario: Boundary with connection details

- **GIVEN** an Integration onboarding guide
- **WHEN** a step creates a credential or identifier on the target
- **THEN** that creation step belongs in integration-prep, and which Entro field receives the value belongs in connection-details

---

## REMOVED Requirements

---

## RENAMED Requirements
