<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

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
fence with the same topology every run (Operator, Agent + entro-connect, Skill
catalog, Vendor CLI / MCP, Entro UI, Connector, Integration).
**Aliases**: none
**Notes**: Written in chat and the Connect log. Not a per-run `.drawio`. Not a
fuller Container diagram of the locked Integration.
