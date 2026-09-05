<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Intro C4 is a mermaid fence

When entro-connect introduces an Integration, it SHALL include the Intro C4 in
chat and in the Connect log as a mermaid `flowchart` fence. The topology MUST be
the same every run (Operator, Agent + entro-connect, Skill catalog, Vendor CLI /
MCP, Entro UI, Connector, Integration). It MUST NOT use ASCII arrows as the
Intro C4. It MUST NOT write a `.drawio` file for the Connect run.

#### Scenario: Intro shows mermaid not ASCII

- **GIVEN** a completed Lock
- **WHEN** the skill introduces the Integration
- **THEN** the Intro in chat MUST contain a mermaid `flowchart` fence for the
  Intro C4
- **AND** the Connect log MUST contain the same fence
- **AND** that section MUST NOT be an ASCII arrow sketch

#### Scenario: Intro C4 is not a per-run draw.io

- **GIVEN** a completed Lock
- **WHEN** the skill persists Intro
- **THEN** it MUST NOT create a `.drawio` beside the Connect log
