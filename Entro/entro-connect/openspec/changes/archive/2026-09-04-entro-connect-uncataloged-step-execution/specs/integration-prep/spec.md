## ADDED Requirements

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
- **THEN** the output MUST go to a Secret sink outside the repository and the skill tree
- **AND** the Connect log MUST record non-secret identifiers only
- **AND** the skill MUST NOT classify the step as an Operator-only step

#### Scenario: Supervised discloses the derived command

- **GIVEN** an Uncataloged Prep step under supervised
- **WHEN** the skill reaches that step
- **THEN** it MUST disclose the derived command and its documentation source
- **AND** the operator MUST execute it
- **AND** the skill MUST NOT run the mutation

---

## MODIFIED Requirements

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
