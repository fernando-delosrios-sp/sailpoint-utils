<!--
Delta spec — the skill selects or gates an Authentication route.
-->

## MODIFIED Requirements

### Requirement: Configure once runs after failed auth-check

When a locked Configuration tool's Tool install entry includes `configureOnce`,
supervised and automated Connect runs SHALL, after an invalid auth-check and
before requesting any sign-in, run the `check` of every cataloged Authentication
route. When exactly one route matches its `suitableWhen`, the skill MUST select
that route without gating. When no route matches, or two or more match, the
skill MUST gate the choice, listing each route's `name` and `whenToPick` in
catalog order; that gate MUST NOT mark any route as recommended and the skill
MUST NOT rank the routes in prose.

For the selected route the skill MUST request its `command` in the operator's
terminal in every Operation mode, including automated, finish that message with
Continue or Help, and MUST NOT run the command itself, unless that route was
selected because its check was already suitable, in which case the skill MUST
skip the command and go straight to the route's sign-in. That request MUST relay
every prompt of that route with its `whereToFind` statement, in catalog order,
plus the route's `docsUrl`; a request that names only the command MUST be treated
as incomplete. A prompt marked `secret` MUST be relayed by label and source only,
with a statement that the value is typed into the vendor CLI; the skill MUST NOT
ask for it, accept it, or echo it. The skill MUST NOT invent prompt guidance that
the catalog does not carry, MUST NOT relay prompts from a route it did not
select, MUST NOT collect answers as Operator inputs, and MUST NOT write them to
the Connect log, which records only the selected route's `name`, that Configure
once was requested, and its outcome.

After Continue the skill SHALL re-run auth-check. A valid session MUST skip
sign-in and record Platform identity. When the session is still invalid and the
selected route's `authOnce` is non-null, the skill MUST request that value — not
the entry-level `authOnce` and not another route's. When the selected route's
`authOnce` is null, the skill MUST NOT request any sign-in and MUST instead
re-request that route's `command` or offer Help. Help MUST collect non-secret
error output and return to Continue or Help. When the picked tool has no
`configureOnce` but another locked Configuration tool has the same
`authCheck.command` and a `configureOnce` object, the skill MUST use that
object, including all of its routes (prefer `aws` when several match). When no
`configureOnce` applies, the skill MUST keep today's auth-check then `authOnce`
path.

#### Scenario: No credentials at all gates the route choice

- **GIVEN** Operation mode is supervised or automated
- **AND** the catalog auth-check reports no valid session
- **AND** no Authentication route matches its `suitableWhen`
- **WHEN** the skill reaches the tools step
- **THEN** it MUST present the routes with their `name` and `whenToPick` in catalog order
- **AND** it MUST NOT mark any route as recommended

#### Scenario: Missing SSO config requests the wizard

- **GIVEN** no Authentication route matches its `suitableWhen`
- **AND** the operator picked the IAM Identity Center route at the gate
- **WHEN** the skill continues the tools step
- **THEN** it MUST request `aws configure sso` in the operator's terminal
- **AND** it MUST NOT run the wizard itself

#### Scenario: Existing SSO profile skips the wizard

- **GIVEN** the catalog auth-check reports no valid session
- **AND** only the IAM Identity Center route matches its `suitableWhen`
- **WHEN** the skill reaches the tools step
- **THEN** it MUST NOT gate the route choice
- **AND** it MUST NOT request `aws configure sso`
- **AND** it MUST request that route's `authOnce` in the operator's terminal

#### Scenario: Two suitable routes gate the choice

- **GIVEN** the catalog auth-check reports no valid session
- **AND** both the access keys route and the Identity Center route match their `suitableWhen`
- **WHEN** the skill reaches the tools step
- **THEN** it MUST gate the route choice before requesting anything

#### Scenario: The request names where each value comes from

- **GIVEN** the operator selected a route whose check was unsuitable
- **WHEN** the skill writes the Configure once request
- **THEN** it MUST list every prompt of that route with its `whereToFind` statement in catalog order
- **AND** it MUST include that route's `docsUrl`
- **AND** it MUST NOT relay prompts belonging to another route

#### Scenario: A secret prompt is never collected

- **GIVEN** the selected route has a prompt marked `secret`
- **WHEN** the skill relays that prompt
- **THEN** it MUST give the label and `whereToFind` and state the value is typed into the vendor CLI
- **AND** it MUST NOT ask the operator for that value in chat
- **AND** the Connect log MUST NOT contain it

#### Scenario: A route without sign-in never requests a login

- **GIVEN** the operator selected the IAM user access keys route
- **AND** that route's `authOnce` is null
- **AND** the auth-check is still invalid after Continue
- **WHEN** the skill continues the tools step
- **THEN** it MUST NOT request `aws sso login`
- **AND** it MUST re-request that route's `command` or offer Help

#### Scenario: Wizard that already signed in skips login

- **GIVEN** the operator completed the selected route's command
- **AND** the catalog auth-check now reports a valid session
- **WHEN** the skill continues the tools step
- **THEN** it MUST skip sign-in
- **AND** it MUST record Platform identity

#### Scenario: Wizard answers stay out of chat and the log

- **GIVEN** the operator is answering the selected route's command
- **WHEN** the skill records the tools step
- **THEN** it MUST NOT collect those answers as Operator inputs
- **AND** the Connect log MUST record only the selected route's `name`, that Configure once was requested, and its outcome

#### Scenario: Terraform uses the AWS Configure once object

- **GIVEN** the Lock lists `aws` and `terraform` as Configuration tools
- **AND** the picked tool is `terraform`
- **AND** `terraform` omits `configureOnce`
- **AND** `aws` has `configureOnce` and the same `authCheck.command`
- **WHEN** the terraform auth-check reports no valid session
- **THEN** the skill MUST use the `aws` Configure once object
- **AND** it MUST offer the same routes and relay the selected route's prompts
