<!--
Delta spec — Intro C4 becomes the locked Integration's Configuration topology.
-->

## MODIFIED Requirements

### Requirement: Intro C4 is a mermaid fence

When entro-connect introduces an Integration, it SHALL include the Intro C4 in
chat and in the Connect log as a mermaid `flowchart` fence that draws the locked
Integration's Configuration topology. The fence SHALL use these node roles: the
Identity object Entro authenticates as, the permission grants attached to it, the
reach those grants cover, the credential the operator carries to Entro, and the
Entro side — the Connection and its Connector. Every node MUST be derived from
the locked row: Identity object and permission grants from Typed action
`expectedChange` and `target`, reach from locked Coverages and their Typed action
targets, the credential from `connectionFields`, and the Connector from
`hosting`. A role the locked row does not name MUST be omitted rather than
invented. Skipped Coverages MUST NOT appear as reach. Secret Connection details
MUST appear by field name only, never as a value. The fence MUST separate the
vendor boundary from Entro using subgraphs and MUST assign C4 roles with
`classDef`. It MUST NOT draw the Connect run machinery — Operator, Agent +
entro-connect, Skill catalog, Vendor CLI / MCP. It MUST NOT use ASCII arrows as
the Intro C4. It MUST NOT write a `.drawio` file for the Connect run.

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

#### Scenario: Intro C4 shows what the Integration needs configured

- **GIVEN** a Lock on Microsoft Ecosystem with the Copilot Studio Coverage
  included
- **WHEN** the skill draws the Intro C4
- **THEN** the fence MUST name the Entra app registration as the Identity object
- **AND** it MUST show its admin-consented Graph permissions and Azure roles as
  permission grants
- **AND** it MUST show the Dataverse environments and SharePoint / OneDrive as
  reach
- **AND** it MUST show the Entro Connection with its Connection detail names and
  the Worker Group kind derived from `hosting`

#### Scenario: Two Integrations draw different fences

- **GIVEN** one Connect run locked on Microsoft Ecosystem and another locked on a
  different Add New Account target
- **WHEN** each run draws its Intro C4
- **THEN** the two fences MUST differ in their nodes
- **AND** neither MUST be a copy of an example fence held in the skill

#### Scenario: Skipped Coverage is absent

- **GIVEN** a Lock that skips a cataloged Coverage
- **WHEN** the skill draws the Intro C4
- **THEN** that Coverage MUST NOT appear as reach
- **AND** its Coverage-specific vendor objects MUST NOT appear as nodes

#### Scenario: Secret Connection detail is named only

- **GIVEN** a locked row with a Connection detail marked secret
- **WHEN** the skill draws the Intro C4
- **THEN** the fence MUST show that detail as a field name
- **AND** it MUST NOT contain a secret value

#### Scenario: Thin row omits a role

- **GIVEN** a locked row whose Typed actions name no vendor scope beyond the
  Identity object
- **WHEN** the skill draws the Intro C4
- **THEN** the reach subgraph MUST be omitted
- **AND** the skill MUST NOT invent a node to fill that role
