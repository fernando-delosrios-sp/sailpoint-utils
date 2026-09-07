<!--
Delta spec — Configure once carries Authentication routes.
-->

## MODIFIED Requirements

### Requirement: Tool install MAY record Configure once

A `toolInstall` entry MAY include a nested `configureOnce` object whose only
field is `methods`, a non-empty ordered list of Authentication routes. Each
route SHALL carry `name`, `whenToPick`, `check` (`command`, `sourceUrl`,
`retrievedAt`), `suitableWhen`, `command`, `prompts`, `credentialBoundary`,
`docsUrl`, `sourceUrl`, `retrievedAt`, and `authOnce`, where `authOnce` MAY be
null to record that the route has no sign-in step. `whenToPick` SHALL state, in
non-secret prose, the situation in which an operator chooses that route.
`prompts` SHALL be a non-empty ordered list of `{prompt, whereToFind}` objects,
one per question that route's command asks, in the order it asks them; a prompt
MAY set `secret` to true. `prompt` SHALL be the label the command displays and
`whereToFind` SHALL be a non-secret statement of where the operator obtains that
value. A route `check.command` SHALL test for the presence of configuration by
name only, MUST NOT print matched lines, and MUST NOT read a credential value.
When `configureOnce` is present, the entry-level `authOnce` SHALL equal the
`authOnce` of one of its routes. The catalog writer SHALL emit that object on
both the ingest `toolInstall` map and both Skill Tool install files. Validation
MUST fail when `configureOnce` is present and `methods` is empty, when a route
omits any of those fields, when a route's `prompts` is empty, when a prompt
entry lacks `prompt` or `whereToFind`, when no route's `authOnce` matches the
entry-level `authOnce`, or when any field contains a secret-shaped value.
Validation MUST succeed when `configureOnce` is omitted and when a route sets
`authOnce` to null.

The `aws` entry MUST record two routes. The IAM user access keys route MUST use
`command` `aws configure`, a `check.command` that inspects the shared
credentials file for `aws_access_key_id`, `authOnce` null, and a
`credentialBoundary` naming the shared credentials file and its long-lived keys;
its prompts MUST cover the access key ID, the secret access key, the default
region, and the output format, the secret access key prompt MUST set `secret`,
and the access key prompts MUST name the IAM console or the credentials CSV as
the source. The IAM Identity Center route MUST use `command` `aws configure sso`,
a `check.command` that inspects the AWS config file (not the credentials file)
for `sso_session` or `sso_start_url`, `authOnce` `aws sso login`, and a
`credentialBoundary` naming the vendor CLI token cache; its prompts MUST cover
the SSO session name, SSO start URL, SSO region, registration scopes, account,
role, CLI default region, output format, and profile name, and the start URL and
SSO region entries MUST name the AWS access portal as the source. The `az` entry
MUST omit `configureOnce`. The `terraform` entry MUST omit `configureOnce`.

#### Scenario: AWS records Configure once without secrets

- **GIVEN** a Tool install catalog entry for `aws`
- **WHEN** the Integration index and Skill Tool install files are written
- **THEN** `configureOnce.methods` MUST contain a route with `command` `aws configure` and a route with `command` `aws configure sso`
- **AND** each route MUST carry its own `whenToPick`, `check`, `prompts`, `credentialBoundary`, and `docsUrl`
- **AND** the entry MUST NOT contain API keys, tokens, or passwords

#### Scenario: The access keys route records no sign-in

- **GIVEN** the `aws` IAM user access keys route
- **WHEN** the catalog is written
- **THEN** its `authOnce` MUST be null
- **AND** its `credentialBoundary` MUST name the shared credentials file holding long-lived keys
- **AND** its secret access key prompt MUST set `secret` to true

#### Scenario: Route checks never expose credential values

- **GIVEN** the `aws` route checks
- **WHEN** the catalog is written
- **THEN** the access keys check MUST test the shared credentials file for `aws_access_key_id` without printing matched lines
- **AND** the Identity Center check MUST target the AWS config file, not `credentials`

#### Scenario: AWS prompts name where each value comes from

- **GIVEN** the `aws` IAM Identity Center route
- **WHEN** the Integration index and Skill Tool install files are written
- **THEN** `prompts` MUST list the SSO session name, start URL, SSO region, registration scopes, account, role, CLI default region, output format, and profile name in wizard order
- **AND** the start URL and SSO region entries MUST name the AWS access portal
- **AND** the route MUST include a `docsUrl` for the vendor wizard page

#### Scenario: Azure CLI omits Configure once

- **GIVEN** a Tool install catalog entry for `az`
- **WHEN** the Integration index is written
- **THEN** that entry MUST NOT include `configureOnce`

#### Scenario: Terraform does not duplicate the AWS wizard

- **GIVEN** a Tool install catalog entry for `terraform`
- **WHEN** the Integration index is written
- **THEN** that entry MUST NOT include `configureOnce`

#### Scenario: Missing Configure once fields fail validation

- **GIVEN** a `toolInstall` entry whose `configureOnce` route omits `check.command` or `whenToPick`
- **WHEN** the catalog is validated
- **THEN** validation MUST fail

#### Scenario: Configure once without prompts fails validation

- **GIVEN** a `toolInstall` entry whose `configureOnce` has an empty `methods` list
- **WHEN** the catalog is validated
- **THEN** validation MUST fail
- **AND** validation MUST also fail when a route's `prompts` is empty or a prompt entry omits `whereToFind`

#### Scenario: Entry-level auth-once must match a route

- **GIVEN** a `toolInstall` entry whose `configureOnce` routes name `aws sso login` and null
- **WHEN** the entry-level `authOnce` is some other command
- **THEN** validation MUST fail
