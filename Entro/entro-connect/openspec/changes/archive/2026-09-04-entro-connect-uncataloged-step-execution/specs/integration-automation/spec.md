## MODIFIED Requirements

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
