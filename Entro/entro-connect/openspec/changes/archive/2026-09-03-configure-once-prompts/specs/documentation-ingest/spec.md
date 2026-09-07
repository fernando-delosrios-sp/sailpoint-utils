<!--
Delta spec — documentation-ingest
-->

## MODIFIED Requirements

### Requirement: Tool install MAY record Configure once

A `toolInstall` entry MAY include a nested `configureOnce` object with `command`,
`check` (`command`, `sourceUrl`, `retrievedAt`), `suitableWhen`, `prompts`,
`docsUrl`, `sourceUrl`, and `retrievedAt`. `prompts` SHALL be a non-empty ordered
list of `{prompt, whereToFind}` objects, one per question the vendor command asks,
in the order it asks them; `prompt` SHALL be the label the command displays and
`whereToFind` SHALL be a non-secret statement of where the operator obtains that
value. The catalog writer SHALL emit that object on both the ingest `toolInstall`
map and both Skill Tool install files. Validation MUST fail when `configureOnce`
is present but any of those fields is missing, when `prompts` is empty, when a
prompt entry lacks `prompt` or `whereToFind`, or when any field contains a
secret-shaped value. Validation MUST succeed when `configureOnce` is omitted.
The `aws` entry MUST include Configure once whose `command` is `aws configure sso`
and whose `check.command` inspects the AWS config file (not the credentials file)
for `sso_session` or `sso_start_url`. The `aws` prompts MUST cover the SSO session
name, SSO start URL, SSO region, registration scopes, account, role, CLI default
region, output format, and profile name, and the start URL and SSO region entries
MUST name the AWS access portal as the source. The `az` entry MUST omit
`configureOnce`. The `terraform` entry MUST omit `configureOnce`.

#### Scenario: AWS records Configure once without secrets

- **GIVEN** a Tool install catalog entry for `aws`
- **WHEN** the Integration index and Skill Tool install files are written
- **THEN** that entry MUST include `configureOnce.command` `aws configure sso`
- **AND** `check.command` MUST target the AWS config file, not `credentials`
- **AND** the entry MUST NOT contain API keys, tokens, or passwords

#### Scenario: AWS prompts name where each value comes from

- **GIVEN** the `aws` Configure once object
- **WHEN** the Integration index and Skill Tool install files are written
- **THEN** `prompts` MUST list the SSO session name, start URL, SSO region, registration scopes, account, role, CLI default region, output format, and profile name in wizard order
- **AND** the start URL and SSO region entries MUST name the AWS access portal
- **AND** the object MUST include a `docsUrl` for the vendor wizard page

#### Scenario: Azure CLI omits Configure once

- **GIVEN** a Tool install catalog entry for `az`
- **WHEN** the Integration index is written
- **THEN** that entry MUST NOT include `configureOnce`

#### Scenario: Terraform does not duplicate the AWS wizard

- **GIVEN** a Tool install catalog entry for `terraform`
- **WHEN** the Integration index is written
- **THEN** that entry MUST NOT include `configureOnce`

#### Scenario: Missing Configure once fields fail validation

- **GIVEN** a `toolInstall` entry that sets `configureOnce` without `check.command`
- **WHEN** the catalog is validated
- **THEN** validation MUST fail

#### Scenario: Configure once without prompts fails validation

- **GIVEN** a `toolInstall` entry whose `configureOnce` has an empty `prompts` list
- **WHEN** the catalog is validated
- **THEN** validation MUST fail
- **AND** validation MUST also fail when a prompt entry omits `whereToFind`
