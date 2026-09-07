<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Prep steps are the ordered catalog list

Integration prep for a locked Add New Account target SHALL be the `prepSteps` of
the locked Setup method when the row has Setup methods, otherwise the row's
`prepSteps`, then any additive Coverage `prepSteps` included in the Lock. A later
skill MUST NOT invent steps Entro does not catalog. Each step's `instruction` in
the index SHALL be sufficient without opening ingested pages.

#### Scenario: Operator follows cataloged steps

- **GIVEN** a Lock that includes a Setup method with `prepSteps`
- **WHEN** an operator or skill performs Integration prep
- **THEN** they MUST follow that list in order
- **AND** they MUST append Coverage `prepSteps` after parent steps when those Coverages are in the Lock

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
the skill SHALL disclose the exact change, run vendor preview when the catalog
says it is supported, and gate Approve, adjust (Operator inputs or remaining
Operation mode), or stop. Typed action definitions MUST NOT be rewritten at run
time.

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

## MODIFIED Requirements

### Requirement: Per-integration preparation is explicit

For each supported Integration, the project SHALL record the preparation steps Entro
requires on that target (identities, apps, roles, scopes, network, or equivalent)
as curated Prep steps on the Integration index. Fit `preferred` paths SHALL also
record Typed actions for those steps.

#### Scenario: Operator follows integration prep

- **GIVEN** an Integration that appears in Entro's onboarding catalog and has ingested documentation
- **WHEN** an operator (or later skill) needs to prepare that Integration
- **THEN** they MUST be able to follow a complete, ordered list of target-side steps without inventing requirements Entro does not document
- **AND** that list MUST be the index `prepSteps` for the Lock

### Requirement: Prep is separated from Entro form fill

Integration prep instructions SHALL describe only work done on the Integration target, not the
fields typed into Entro.

#### Scenario: Boundary with connection details

- **GIVEN** an Integration onboarding guide
- **WHEN** a step creates a credential or identifier on the target
- **THEN** that creation step belongs in integration-prep, and which Entro field receives the value belongs in connection-details
