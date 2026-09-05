<!--
Delta spec — integration-automation
-->

## MODIFIED Requirements

### Requirement: Configure once runs after failed auth-check

When a locked Configuration tool's Tool install entry includes `configureOnce`,
supervised and automated Connect runs SHALL, after an invalid auth-check and
before requesting `authOnce`, run the cataloged `configureOnce.check`. When the
check matches `suitableWhen`, the skill MUST skip the wizard and request
`authOnce`. When the check is unsuitable, the skill MUST request
`configureOnce.command` in the operator's terminal in every Operation mode,
including automated, finish that message with Continue or Help, and MUST NOT
run the wizard itself. That request MUST relay every cataloged `prompts` entry
with its `whereToFind` statement, in catalog order, plus the `docsUrl`; a request
that names only the command MUST be treated as incomplete. The skill MUST NOT
invent prompt guidance that the catalog does not carry, MUST NOT collect wizard
answers as Operator inputs, and MUST NOT write them to the Connect log. After
Continue it SHALL re-run auth-check; a valid session MUST skip `authOnce`. Help
MUST collect non-secret error output and return to Continue or Help. When the
picked tool has no `configureOnce` but another locked Configuration tool has the
same `authCheck.command` and a `configureOnce` object, the skill MUST use that
object, including its prompts (prefer `aws` when several match). When no
`configureOnce` applies, the skill MUST keep today's auth-check then `authOnce`
path.

#### Scenario: Missing SSO config requests the wizard

- **GIVEN** Operation mode is supervised or automated
- **AND** the catalog auth-check reports no valid session
- **AND** Configure once check is unsuitable
- **WHEN** the skill reaches the tools step
- **THEN** it MUST request `configureOnce.command` in the operator's terminal
- **AND** it MUST NOT run the wizard itself

#### Scenario: The request names where each value comes from

- **GIVEN** a Configure once request for `aws configure sso`
- **WHEN** the skill writes that message
- **THEN** it MUST list every cataloged prompt with its `whereToFind` statement in catalog order
- **AND** it MUST include the cataloged `docsUrl`
- **AND** it MUST NOT summarise the prompts as a bare list of value names

#### Scenario: Wizard answers stay out of chat and the log

- **GIVEN** the operator is answering the vendor wizard
- **WHEN** the skill records the tools step
- **THEN** it MUST NOT collect those answers as Operator inputs
- **AND** the Connect log MUST record only that Configure once was requested and its outcome

#### Scenario: Wizard that already signed in skips login

- **GIVEN** the operator completed Configure once
- **AND** the catalog auth-check now reports a valid session
- **WHEN** the skill continues the tools step
- **THEN** it MUST skip `authOnce`
- **AND** it MUST record Platform identity

#### Scenario: Existing SSO profile skips the wizard

- **GIVEN** the catalog auth-check reports no valid session
- **AND** Configure once check matches `suitableWhen`
- **WHEN** the skill reaches the tools step
- **THEN** it MUST NOT request `configureOnce.command`
- **AND** it MUST request `authOnce` in the operator's terminal

#### Scenario: Terraform uses the AWS Configure once object

- **GIVEN** the Lock lists `aws` and `terraform` as Configuration tools
- **AND** the picked tool is `terraform`
- **AND** `terraform` omits `configureOnce`
- **AND** `aws` has `configureOnce` and the same `authCheck.command`
- **WHEN** the terraform auth-check reports no valid session
- **THEN** the skill MUST use the `aws` Configure once object
- **AND** it MUST relay the `aws` prompts with their sources
