<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Integration index is keyed by Add New Account target

Ingest SHALL write a curated JSON index of Add New Account targets. Each row SHALL be
identified by its Add New Account tile and its in-form target selection, and that pair MUST
be unique across the index. Each row SHALL carry its category, the ingested documentation
pages for that target, its setup methods, its authentication methods, and its connector
requirement. Setup methods and authentication methods MUST NOT appear as rows of their own.
Rows MUST NOT carry connector deployment topologies or generic connector documentation, since
those describe the Entro Connector product rather than any one target. IDE plugins, Entro
Connector deployment docs, SSO setup, CLI utilities, and other non-integration sections MUST
NOT appear.

#### Scenario: Integration index lists curated targets

- **GIVEN** the curated catalog includes genuine Add New Account targets and excludes IDE marketplace pages
- **WHEN** ingest writes the documentation tree
- **THEN** `integrations.json` MUST include each curated target with tile, target selection, category, documentation pages, and connector requirement
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
- **THEN** the row MUST use the tile label from the documented Add New Account navigation path

#### Scenario: Collapsed rows keep their documentation

- **GIVEN** several documentation sections that resolve to one Add New Account target
- **WHEN** those rows collapse into one
- **THEN** the surviving row MUST list every one of those documentation pages

### Requirement: Connector requirement carries resolvable evidence

Every Integration index row whose `connectorRequirement` is not `unknown` SHALL carry a
requirement evidence citation naming an ingested documentation page and the form label or
field list on that page which settles the question. Validation MUST reject a row whose
citation does not resolve to a file in the documentation tree.

#### Scenario: Required requirement cites the documented field

- **GIVEN** a target whose connection form is documented with a Worker Group (Connector) field
- **WHEN** the Integration index is written
- **THEN** that row MUST be `required` with evidence basis `worker-group-field-documented`
- **AND** the cited page MUST be an existing file in the documentation tree

#### Scenario: Not-required requirement cites a complete field list

- **GIVEN** a target whose documentation gives a complete connection form field list with no Worker Group in it
- **WHEN** the Integration index is written
- **THEN** that row MUST be `not-required` with evidence basis `complete-field-list-omits-worker-group`

#### Scenario: Undocumented connector requirement stays unknown

- **GIVEN** a target whose ingested pages never state whether its form has a Worker Group field
- **WHEN** the Integration index is written
- **THEN** that row MUST be `unknown` and MUST NOT carry requirement evidence
- **AND** the row MUST NOT be recorded as `not-required`

#### Scenario: Unproven claim fails validation

- **GIVEN** an Integration index row asserting `required` or `not-required` with no evidence citation, or a citation naming a path absent from the documentation tree
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that row

---

## REMOVED Requirements

### Requirement: Integration index lists Add New Account variants

**Reason**: The requirement keyed rows by variant, which in practice meant one row per
documentation section and setup method. Rows split that way can describe the same Add New
Account connection form, and they did: Amazon Web Services appeared twice with contradictory
connector requirements. The requirement also mandated `connectorDeployments` and
`connectorDocumentation` per row, both of which held identical values on every row and so
distinguished nothing, while the second presented generic connector-deployment pages as
though they were evidence for a specific row's requirement.

**Migration**: Replaced by `Integration index is keyed by Add New Account target` and
`Connector requirement carries resolvable evidence`. Rows are re-keyed to `(tile,
targetSelection)`; setup and authentication methods become row attributes; the two connector
fields are dropped in favour of one requirement evidence citation, and the four connector
topologies are documented once at product level.
