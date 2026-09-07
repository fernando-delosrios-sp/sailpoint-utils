<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Configuration topology terms

The glossary SHALL define Configuration topology and Identity object with the
definitions in Term entries below.

#### Scenario: Specs use Configuration topology

- **GIVEN** a change authors entro-connect requirements about what a locked
  Integration must have configured for Entro to connect
- **WHEN** it names that shape
- **THEN** it MUST use Configuration topology
- **AND** it MUST NOT call it the integration architecture or the connection flow

#### Scenario: Specs use Identity object

- **GIVEN** a change authors requirements about the vendor-side principal Entro
  authenticates as
- **WHEN** it names that principal
- **THEN** it MUST use Identity object
- **AND** it MUST NOT call it a service account or a connector identity

---

## MODIFIED Requirements

### Requirement: C4 flowchart terms

The glossary SHALL define C4 flowchart and Intro C4 with the definitions in Term
entries below.

#### Scenario: Specs use C4 flowchart not draw.io as the default

- **GIVEN** a change authors design or skill requirements about a Container-level
  architecture picture
- **WHEN** it names that picture
- **THEN** it MUST use C4 flowchart
- **AND** it MUST NOT treat `.drawio` or mermaid `C4Container` as the canonical
  format

#### Scenario: Specs use Intro C4

- **GIVEN** a change authors entro-connect requirements about the diagram in
  Intro
- **WHEN** it names that diagram
- **THEN** it MUST use Intro C4
- **AND** it MUST NOT call ASCII arrows the Intro C4
- **AND** it MUST NOT define the Intro C4 as one fixed topology repeated every
  run

## Term entries

### Term: C4 flowchart
**Context**: architecture-diagrams
**Definition**: A mermaid `flowchart` whose nodes and subgraphs map to C4
Container roles (Person, Container, Database, External System, system
boundary). It is the architecture picture GitHub and chat draw.
**Aliases**: mermaid C4, container diagram
**Notes**: Default for ferspec `design.md` §Architecture and the c4-diagram skill.
Not mermaid `C4Container` / `C4Context`. Not a `.drawio` file.

### Term: Intro C4
**Context**: integration-automation
**Definition**: The Connect Intro architecture picture: one mermaid `flowchart`
fence drawing the locked Integration's Configuration topology, derived from the
locked row.
**Aliases**: none
**Notes**: Written in chat and the Connect log. Varies per Integration; the node
roles are fixed, the nodes are not. Does not draw the Connect run machinery
(Operator, Agent + entro-connect, Skill catalog, Vendor CLI / MCP). Not a per-run
`.drawio`.

### Term: Configuration topology
**Context**: integration-automation
**Definition**: What a locked Integration must have configured on the vendor side
for Entro to connect, and how Entro reaches it: the Identity object, the
permission grants attached to it, the vendor scopes and locked Coverages those
grants reach, the credential the operator carries to Entro, and the Entro-side
Connection and Connector.
**Aliases**: none
**Notes**: Derived per run from the locked row — Typed action `expectedChange`
and `target`, locked Coverages, `connectionFields`, `hosting`. Pre-mutation
intent, not probed state. Not the Connect run machinery. Not a deployment
topology.

### Term: Identity object
**Context**: integration-automation
**Definition**: The vendor-side principal Entro authenticates as — an Entra app
registration, an AWS IAM role, an Okta API service app — that permission grants
attach to.
**Aliases**: none
**Notes**: The node every other Configuration topology node hangs off. Named from
Typed action `expectedChange` / `target`, never invented. Not a Connector, not an
Operator identity.
