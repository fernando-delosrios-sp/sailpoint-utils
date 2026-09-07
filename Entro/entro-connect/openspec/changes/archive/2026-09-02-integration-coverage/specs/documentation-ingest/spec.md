<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Integration index lists Coverages

Each Integration index row SHALL carry a list of Coverages for that Add New Account
target. A Coverage SHALL have a unique name on that row and SHALL cite at least one
ingested documentation page from a GitBook section that resolves to the target and is
not that target's core onboarding, permissions-reference, or troubleshooting docs.
Permission-group headings alone MUST NOT create a Coverage. A target with no such
section MUST carry an empty Coverage list. Validation MUST reject a Coverage whose
cited path is absent from the documentation tree, or whose name repeats on the same
row.

#### Scenario: Collapsed GitBook section becomes a Coverage

- **GIVEN** GitBook sections for SharePoint / OneDrive and Microsoft Copilot Studio
  whose pages resolve to the Microsoft Ecosystem Add New Account target
- **WHEN** the Integration index is written
- **THEN** the Microsoft Ecosystem row MUST list Coverages named SharePoint / OneDrive
  and Copilot Studio
- **AND** those Coverages MUST cite ingested pages from those sections
- **AND** Microsoft Copilot Studio MUST NOT appear as an Add New Account target

#### Scenario: Permission-group heading is not a Coverage

- **GIVEN** Microsoft Ecosystem documentation that names optional Graph permission
  groups for Copilot chats, Defender, or Teams secrets without a GitBook section of
  their own
- **WHEN** the Integration index is written
- **THEN** those groups MUST NOT appear as Coverages on the Microsoft Ecosystem row

#### Scenario: Product-level Git clone scanning is not a Coverage

- **GIVEN** a Git clone scanning GitBook section that applies to GitHub, GitLab, and
  Bitbucket
- **WHEN** the Integration index is written
- **THEN** Git clone scanning MUST NOT appear as a Coverage on those targets

#### Scenario: Other collapsed sections are Coverages on their target

- **GIVEN** ingested GitBook sections for GitHub real-time scanning, GitHub Cloud
  Enterprise S3 log streaming, CrowdStrike Falcon RTR, Jira real-time scanning, and
  SailPoint NHI aggregation
- **WHEN** the Integration index is written
- **THEN** each MUST appear as a Coverage on the Add New Account target that section
  belongs to
- **AND** GitHub real-time scanning MUST appear on each GitHub target row
- **AND** GitHub Enterprise S3 log streaming MUST NOT appear on GitHub Enterprise Server

#### Scenario: Coverage citation must resolve

- **GIVEN** an Integration index row whose Coverage cites a documentation path
- **WHEN** the index is validated
- **THEN** validation MUST fail if that path is not a file in the documentation tree
- **AND** validation MUST fail if two Coverages on the same row share a name

#### Scenario: Empty Coverage list is valid

- **GIVEN** an Add New Account target whose ingested pages are only core onboarding,
  permissions, and troubleshooting
- **WHEN** the Integration index is written
- **THEN** that row MUST carry an empty Coverage list
- **AND** validation MUST succeed for that field

---

## MODIFIED Requirements

### Requirement: Integration index is keyed by Add New Account target

Ingest SHALL write a curated JSON index of Add New Account targets. Each row SHALL be
identified by its Add New Account tile and its in-form target selection, and that pair MUST
be unique across the index. Each row SHALL carry its category, the ingested documentation
pages for that target, its setup methods, its authentication methods, its connector
requirement, and its Coverages. Setup methods and authentication methods MUST NOT appear as
rows of their own. A GitBook section whose documented Add New Account path names a tile
the Add New Account provider list does not offer MUST NOT become a row; it MUST be a
Coverage of the target that section actually connects through. Rows MUST NOT carry
connector deployment topologies or generic connector documentation, since those describe
the Entro Connector product rather than any one target. IDE plugins, Entro Connector
deployment docs, SSO setup, CLI utilities, and other non-integration sections MUST NOT
appear.

#### Scenario: Integration index lists curated targets

- **GIVEN** the curated catalog includes genuine Add New Account targets and excludes IDE marketplace pages
- **WHEN** ingest writes the documentation tree
- **THEN** `integrations.json` MUST include each curated target with tile, target selection, category, documentation pages, connector requirement, and Coverages
- **AND** excluded documentation sections MUST NOT appear as Integrations

#### Scenario: One target, one row

- **GIVEN** two documented setup methods that lead to the same Add New Account connection form
- **WHEN** the Integration index is written
- **THEN** they MUST produce a single row carrying both setup methods
- **AND** validation MUST fail if the same tile and target selection pair appears twice

#### Scenario: In-form target selections are distinct rows

- **GIVEN** one tile that offers several in-form target selections with different connection forms
- **WHEN** the Integration index is written
- **THEN** each target selection MUST be its own row under that tile

#### Scenario: Authentication method does not create a row

- **GIVEN** a target whose form accepts more than one credential type
- **WHEN** the Integration index is written
- **THEN** those credential types MUST appear as that row's authentication methods, not as separate rows

#### Scenario: Targets are named as Entro labels them

- **GIVEN** a documentation section whose name differs from the Add New Account tile label
- **WHEN** the Integration index is written
- **THEN** the row MUST use the tile label from the Add New Account provider list
- **AND** when the documented navigation path names a tile that exists on that list, the row MUST use that label

#### Scenario: Collapsed rows keep their documentation

- **GIVEN** several documentation sections that resolve to one Add New Account target
- **WHEN** those rows collapse into one
- **THEN** the surviving row MUST list every one of those documentation pages

#### Scenario: Missing provider-list tile is not a target

- **GIVEN** a GitBook section whose documented Add New Account path names a tile the provider list does not offer
- **WHEN** the Integration index is written
- **THEN** that section MUST NOT appear as an Add New Account target
