<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Integration index lists Configuration tools

Each Integration index row SHALL carry a non-empty list of Configuration tools for
that Add New Account target. Each entry SHALL have a Fit of `preferred`, `usable`,
`env-backed`, or `none`. Each entry SHALL have a kind of `cli` or `mcp`; omitted
kind MUST mean `cli`. An entry whose Fit is not `none` and whose kind is `cli`
MUST name a `binary`. An entry whose Fit is not `none` and whose kind is `mcp`
MUST name an `id`. Configuration tools MUST NOT appear as rows of their own.
Validation MUST reject a row with an empty Configuration tool list, an unknown
Fit, or an unknown kind.

#### Scenario: Every target lists Configuration tools

- **GIVEN** the curated catalog of Add New Account targets
- **WHEN** the Integration index is written
- **THEN** each row MUST include a non-empty `configurationTools` list
- **AND** each entry MUST have a Fit of `preferred`, `usable`, `env-backed`, or `none`

#### Scenario: Preferred cloud CLIs are recorded

- **GIVEN** the Microsoft Ecosystem, AWS, and Google Cloud Platform Add New Account targets
- **WHEN** the Integration index is written
- **THEN** Microsoft Ecosystem MUST list `az` and `pwsh` with Fit `preferred`
- **AND** AWS MUST list `aws` with Fit `preferred`
- **AND** Google Cloud Platform MUST list `gcloud` with Fit `preferred`

#### Scenario: GitHub App install is usable not preferred

- **GIVEN** the GitHub Cloud - New Add New Account target whose documented setup is Entro's GitHub App redirect
- **WHEN** the Integration index is written
- **THEN** that row MUST list `gh` with Fit `usable`

#### Scenario: Portal-only targets still list a tool

- **GIVEN** an Add New Account target with no usable official admin CLI and no first-party vendor MCP for Integration prep
- **WHEN** the Integration index is written
- **THEN** that row MUST list at least one Configuration tool with Fit `none`
- **AND** that entry MAY omit `binary` and `id`

#### Scenario: n8n lists a first-party MCP

- **GIVEN** the n8n Add New Account target
- **WHEN** the Integration index is written
- **THEN** that row MUST list a Configuration tool with kind `mcp`, `id` `n8n-mcp`, and Fit `usable`
- **AND** that row MUST NOT rely on Fit `none` as its only tool

#### Scenario: First-party MCP sits beside a CLI

- **GIVEN** the Microsoft Ecosystem and GitHub Cloud - New Add New Account targets
- **WHEN** the Integration index is written
- **THEN** Microsoft Ecosystem MUST list `az` and `pwsh` with kind `cli` (or omitted) and Fit `preferred`
- **AND** Microsoft Ecosystem MUST also list kind `mcp` with `id` `azure-mcp` and Fit `usable`
- **AND** GitHub Cloud - New MUST list `gh` with Fit `usable` and kind `mcp` with `id` `github-mcp`

#### Scenario: Configuration tools are not rows

- **GIVEN** two targets that both use `az`
- **WHEN** the Integration index is written
- **THEN** each target MUST remain its own row
- **AND** `az` MUST NOT appear as an Add New Account target

### Requirement: Integration index carries a Tool install catalog

The Integration index document SHALL include a Tool install catalog object `toolInstall`
keyed by CLI `binary` or MCP `id`. Each entry SHALL record `authOnce`, a Credential
boundary, a `docsUrl`, and preferred install for Windows, macOS, and Linux. Each OS
install SHALL have a `method` and MAY have a `command`; Linux `command` MAY be null
when only the vendor documentation is honest. MCP entries SHALL use method
`mcp-config` on all three OS objects with a null `command`. `docsUrl` MUST be
present on the entry. The catalog MUST NOT put secret values in any field.

#### Scenario: Shared binaries are installed once

- **GIVEN** Microsoft Ecosystem, Microsoft Teams, and Azure DevOps all list `az`
- **WHEN** the Integration index is written
- **THEN** `toolInstall` MUST contain exactly one `az` entry
- **AND** that entry MUST include Windows, macOS, and Linux install objects and a `docsUrl`

#### Scenario: Auth once is recorded without secrets

- **GIVEN** a Tool install catalog entry for `aws`
- **WHEN** the Integration index is written
- **THEN** that entry MUST include `authOnce` (for example `aws sso login`)
- **AND** that entry MUST name a Credential boundary that is a CLI token cache or gitignored env file
- **AND** the entry MUST NOT contain API keys, tokens, or passwords

#### Scenario: jenkins-cli is not a global package

- **GIVEN** the Jenkins Add New Account target lists `jenkins-cli`
- **WHEN** the Integration index is written
- **THEN** the `jenkins-cli` Tool install catalog entry MUST describe obtaining the jar from the Jenkins controller
- **AND** it MUST NOT claim a Windows winget package id as the only install path

### Requirement: Coverage Configuration tools are additive

A Coverage MAY list extra Configuration tools. Tools on the parent Add New Account
target ALWAYS apply to that Coverage. An empty Coverage `configurationTools` list
MUST mean inherit only. Extra Coverage tools MUST follow the same Fit and binary
rules as row tools. Microsoft Copilot Studio MUST remain a Coverage of Microsoft
Ecosystem and MUST NOT become a row because it needs Configuration tools.

#### Scenario: Copilot Studio inherits Microsoft Ecosystem tools

- **GIVEN** Microsoft Ecosystem lists `az` and `pwsh` and Coverages SharePoint / OneDrive and Copilot Studio
- **WHEN** the Integration index is written
- **THEN** those Coverages MUST NOT be required to repeat `az` and `pwsh`
- **AND** Copilot Studio MUST NOT appear as an Add New Account target

#### Scenario: GitHub S3 log streaming adds aws

- **GIVEN** GitHub Cloud targets with Coverage Enterprise S3 log streaming
- **WHEN** the Integration index is written
- **THEN** that Coverage MUST list `aws` as an extra Configuration tool
- **AND** GitHub Enterprise Server MUST NOT list that Coverage

### Requirement: Configuration tool binaries resolve in the Tool install catalog

Validation MUST fail when a Configuration tool whose Fit is not `none` names a
CLI `binary` or MCP `id` absent from `toolInstall`. Validation MUST fail when
`toolInstall` contains a key that no row or Coverage references. A `none` entry
without a `binary` or `id` MUST succeed.

#### Scenario: Missing install entry fails validation

- **GIVEN** a row lists `binary` `az` with Fit `preferred`
- **AND** `toolInstall` has no `az` key
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that binary

#### Scenario: Orphan install entry fails validation

- **GIVEN** `toolInstall` contains a binary no row or Coverage lists
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that key

#### Scenario: Fit none without binary succeeds

- **GIVEN** a row lists a Configuration tool with Fit `none` and no `binary`
- **WHEN** the index is validated
- **THEN** validation MUST succeed for that entry

#### Scenario: MCP without id fails validation

- **GIVEN** a row lists a Configuration tool with kind `mcp`, Fit `usable`, and no `id`
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that the MCP entry needs an `id`
