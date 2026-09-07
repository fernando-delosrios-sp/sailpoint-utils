<!--
Delta spec — integration-automation
-->

## ADDED Requirements

### Requirement: Configure once runs after failed auth-check

When a locked Configuration tool's Tool install entry includes `configureOnce`,
supervised and automated Connect runs SHALL, after an invalid auth-check and
before requesting `authOnce`, run the cataloged `configureOnce.check`. When the
check matches `suitableWhen`, the skill MUST skip the wizard and request
`authOnce`. When the check is unsuitable, the skill MUST request
`configureOnce.command` in the operator's terminal in every Operation mode,
including automated, finish that message with Continue or Help, and MUST NOT
run the wizard itself. After Continue it SHALL re-run auth-check; a valid
session MUST skip `authOnce`. Help MUST collect non-secret error output and
return to Continue or Help. When the picked tool has no `configureOnce` but
another locked Configuration tool has the same `authCheck.command` and a
`configureOnce` object, the skill MUST use that object (prefer `aws` when
several match). When no `configureOnce` applies, the skill MUST keep today's
auth-check then `authOnce` path.

#### Scenario: Missing SSO config requests the wizard

- **GIVEN** Operation mode is supervised or automated
- **AND** the catalog auth-check reports no valid session
- **AND** Configure once check is unsuitable
- **WHEN** the skill reaches the tools step
- **THEN** it MUST request `configureOnce.command` in the operator's terminal
- **AND** it MUST NOT run the wizard itself

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

---

## MODIFIED Requirements

### Requirement: Auth-once is checked then confirmed

For supervised and automated modes the skill SHALL run the catalog auth-check
and Platform identity query before requesting login. A valid session MUST skip
Configure once and login and gate continue-with-this-environment versus
re-authenticate or help. An invalid session MUST follow Configure once when the
catalog provides it, then request the catalog `authOnce` in the operator's
terminal only if auth-check is still invalid, in automated mode as well as
supervised, and finish that message with Continue (check authentication) or Help
(authentication issues). Help MUST collect non-secret error output, diagnose it,
and return to that gate. The skill MUST NOT accept a login secret into session
and MUST NOT run `authOnce` or Configure once itself.

#### Scenario: Valid session skips login

- **GIVEN** the catalog auth-check reports an authenticated session
- **WHEN** the skill records Platform identity
- **THEN** it MUST skip Configure once
- **AND** it MUST skip a new login
- **AND** it MUST gate confirmation of the observed environment before configuration

#### Scenario: Operator requests help after login

- **GIVEN** the operator chose Help after `authOnce`
- **WHEN** non-secret CLI output is available
- **THEN** the skill MUST diagnose that output
- **AND** it MUST return to Continue or Help
- **AND** it MUST NOT treat authentication as complete until the auth-check succeeds

#### Scenario: Automated still asks the operator to sign in

- **GIVEN** Operation mode is automated
- **AND** the catalog auth-check reports no valid session
- **AND** Configure once does not apply or already succeeded
- **WHEN** the skill still has no valid session
- **THEN** it MUST request the catalog `authOnce` in the operator's terminal
- **AND** it MUST NOT run the login itself
