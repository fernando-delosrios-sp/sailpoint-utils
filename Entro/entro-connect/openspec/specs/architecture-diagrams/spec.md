# architecture-diagrams

## Purpose

Container-level architecture pictures for this project. The generated format is a
C4 flowchart: mermaid `flowchart` with C4 roles via shapes, `classDef`, and
subgraphs, inline in `design.md` §Architecture.

## Requirements

### Requirement: C4 flowchart is the only generated Container diagram

When a change needs a Container-level architecture picture, the project SHALL
emit a C4 flowchart: a mermaid `flowchart` whose nodes and subgraphs map to C4
roles (Person, Container, Database, External System, system boundary). It MUST
NOT generate `.drawio` as the default or required artifact. It MUST NOT use
mermaid `C4Container` or `C4Context` as the default syntax.

#### Scenario: Design Architecture is inline mermaid

- **GIVEN** a change that touches three or more containers
- **WHEN** the agent writes `design.md` §Architecture
- **THEN** that section MUST contain a mermaid `flowchart` fence
- **AND** it MUST NOT require a `diagrams/<change-name>.drawio` file

#### Scenario: c4-diagram skill emits mermaid not draw.io

- **GIVEN** the operator asks for a C4 or container diagram
- **WHEN** the c4-diagram skill runs
- **THEN** it MUST produce a C4 flowchart suitable for `design.md`
- **AND** it MUST NOT write a `.drawio` file unless this change is later
  superseded

#### Scenario: Ferspec design instruction matches mermaid

- **GIVEN** an agent follows the ferspec design artifact instruction
- **WHEN** a C4 is required
- **THEN** the instruction MUST tell the agent to put a C4 flowchart in
  `design.md` §Architecture
- **AND** it MUST NOT instruct writing `diagrams/<change-name>.drawio`

### Requirement: Historical draw.io files stay

Existing `.drawio` files SHALL remain. This capability MUST NOT require converting
or deleting them.

#### Scenario: Older change diagrams are left alone

- **GIVEN** a change directory already contains `diagrams/*.drawio`
- **WHEN** this capability is applied
- **THEN** those files MUST still exist
- **AND** their `design.md` links MAY continue to point at them
