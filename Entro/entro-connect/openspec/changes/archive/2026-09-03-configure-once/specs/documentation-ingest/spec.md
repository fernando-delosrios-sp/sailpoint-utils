<!--
Delta spec — documentation-ingest
-->

## ADDED Requirements

### Requirement: Tool install MAY record Configure once

A `toolInstall` entry MAY include a nested `configureOnce` object with `command`,
`check` (`command`, `sourceUrl`, `retrievedAt`), `suitableWhen`, `sourceUrl`, and
`retrievedAt`. The catalog writer SHALL emit that object on both the ingest
`toolInstall` map and both Skill Tool install files. Validation MUST fail when
`configureOnce` is present but any of those fields is missing or contains a
secret-shaped value. Validation MUST succeed when `configureOnce` is omitted.
The `aws` entry MUST include Configure once whose `command` is `aws configure sso`
and whose `check.command` inspects the AWS config file (not the credentials file)
for `sso_session` or `sso_start_url`. The `az` entry MUST omit `configureOnce`.
The `terraform` entry MUST omit `configureOnce`.

#### Scenario: AWS records Configure once without secrets

- **GIVEN** a Tool install catalog entry for `aws`
- **WHEN** the Integration index and Skill Tool install files are written
- **THEN** that entry MUST include `configureOnce.command` `aws configure sso`
- **AND** `check.command` MUST target the AWS config file, not `credentials`
- **AND** the entry MUST NOT contain API keys, tokens, or passwords

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

---

## MODIFIED Requirements

### Requirement: Tool install catalog carries probes and identity

Each `toolInstall` entry SHALL include a presence check, a Capability probe,
an auth-check, and a Platform identity query, plus existing `authOnce`,
`credentialBoundary`, and install docs. The skill MUST execute only those
cataloged checks. Each probe and action SHALL record an official source URL and
retrieval or version date. An entry MAY also include Configure once; the skill
MUST execute only the cataloged Configure once check and MUST NOT invent a
session-config command.

#### Scenario: Azure CLI has an identity query

- **GIVEN** the `az` `toolInstall` entry
- **WHEN** the Skill catalog is written
- **THEN** it MUST include presence, Capability probe, auth-check, and Platform identity fields
- **AND** those fields MUST NOT require opening `documentation/`

#### Scenario: Configure once is optional on probes

- **GIVEN** a `toolInstall` entry that has complete probes and no `configureOnce`
- **WHEN** the catalog is validated
- **THEN** validation MUST succeed
