## MODIFIED Requirements

### Requirement: Operation mode gates tools and automation

A Connect run SHALL use Operation mode `instructions`, `supervised`, or
`automated`. Automated MUST be offered only when every Prep step selected by the
Lock has a valid Typed action and every required Configuration tool has presence,
Capability probe, auth-check, and Platform identity contracts. When that plan is
incomplete, or when every Configuration tool is Fit `none`, the skill MUST offer
only instructions and supervised and MUST explain why automated is hidden.
Configuration tool install and auth-once SHALL run only for supervised and automated.
The skill SHALL pick tools by matching the locked Setup method when obvious,
otherwise the first Fit preferred, then usable CLI, then MCP. After Approve,
supervised and automated SHALL both execute non-secret-producing cataloged Typed
actions. Secret-producing actions SHALL stay operator-executed. Instructions
(playbook) MUST NOT execute mutations.

#### Scenario: Incomplete typed-action plan hides automated

- **GIVEN** a Lock whose selected Prep steps lack a complete Typed action plan
- **WHEN** the skill offers Operation mode
- **THEN** the options MUST be instructions and supervised
- **AND** automated MUST NOT be offered

#### Scenario: Fit none hides automated

- **GIVEN** a Lock whose Configuration tools are only Fit `none`
- **WHEN** the skill offers Operation mode
- **THEN** the options MUST be instructions and supervised
- **AND** automated MUST NOT be offered

#### Scenario: GitHub Cloud New is not automated

- **GIVEN** the GitHub Cloud - New Lock whose `gh` Fit is `usable`
- **WHEN** the skill offers Operation mode
- **THEN** automated MUST NOT be offered

#### Scenario: Instructions skip tool install

- **GIVEN** the operator chooses instructions
- **WHEN** the skill writes the Connect log
- **THEN** it MUST NOT require Configuration tool install or auth-once

#### Scenario: Supervised and automated both execute safe actions after Approve

- **GIVEN** the operator chose supervised or automated
- **AND** they Approved a non-secret-producing cataloged Typed action
- **WHEN** the skill continues that step
- **THEN** the skill MUST run the disclosed mutation
- **AND** the two modes MUST NOT differ on who executes
