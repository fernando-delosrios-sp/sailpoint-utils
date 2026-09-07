<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Integration index records hosting and derives connector deployment

Each Integration index row MUST carry `hosting` as exactly one of `public`,
`self-hosted`, or `operator-selected`. Validation MUST reject a row that omits
the key or uses any other value. Connector deployment topology MUST be derived
from hosting: `public` maps to SaaS Perimeter; `self-hosted` maps to Docker
Compose or Kubernetes Helm; `operator-selected` follows the operator's form
choice. Rows MUST NOT emit a stored topology list. Kubernetes Helm is the
preferred self-hosted topology when scanning is cluster-native.

#### Scenario: Every row carries a hosting value

- **GIVEN** the curated catalog of Add New Account targets
- **WHEN** the Integration index is written
- **THEN** every row MUST contain `hosting` as `public`, `self-hosted`, or `operator-selected`

#### Scenario: Unknown or missing hosting fails validation

- **GIVEN** an Integration index row that omits `hosting` or sets it to a value other than the three allowed
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that row

#### Scenario: Public hosting derives SaaS Perimeter

- **GIVEN** a row whose `hosting` is `public`
- **WHEN** connector deployment is derived
- **THEN** the derived topology MUST be SaaS Perimeter
- **AND** the row MUST NOT contain a topology list key

#### Scenario: Self-hosted hosting derives Docker or Helm

- **GIVEN** a row whose `hosting` is `self-hosted`
- **WHEN** connector deployment is derived
- **THEN** the derived topologies MUST be Docker Compose and Kubernetes Helm
- **AND** the row MUST NOT contain a topology list key

#### Scenario: Operator-selected hosting follows the form

- **GIVEN** a target whose connection form lets the operator choose cloud or self-hosted (GitLab, n8n)
- **WHEN** the Integration index is written
- **THEN** that row MUST be `operator-selected`
- **AND** it MUST remain a single row
- **AND** derived topology MUST follow the operator's form choice rather than a stored list

---

## MODIFIED Requirements

### Requirement: Integration index is keyed by Add New Account target

Ingest SHALL write a curated JSON index of Add New Account targets. Each row SHALL be
identified by its Add New Account tile and its in-form target selection, and that pair MUST
be unique across the index. Each row SHALL carry its category, the ingested documentation
pages for that target, its setup methods, its authentication methods, its Coverages, and
its hosting. Setup methods and authentication methods MUST NOT appear as rows of their own. A GitBook
section whose documented Add New Account path names a tile the Add New Account provider
list does not offer MUST NOT become a row; it MUST be a Coverage of the target that
section actually connects through. Rows MUST NOT carry connector requirement, connector
evidence, connector deployment topologies, or generic connector documentation, since a
connector is always required and topologies are derived from hosting rather
than stored on any one target. IDE plugins, Entro Connector deployment docs, SSO setup, CLI
utilities, and other non-integration sections MUST NOT appear.

#### Scenario: Integration index lists curated targets

- **GIVEN** the curated catalog includes genuine Add New Account targets and excludes IDE marketplace pages
- **WHEN** ingest writes the documentation tree
- **THEN** `integrations.json` MUST include each curated target with tile, target selection, category, documentation pages, Coverages, and hosting
- **AND** each row MUST omit `connectorRequirement` and `connectorEvidence`
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
