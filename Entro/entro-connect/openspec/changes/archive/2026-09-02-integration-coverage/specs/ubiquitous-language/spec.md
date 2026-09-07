<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Coverage term

The glossary SHALL define Coverage with the definition in Term entries below. Notes on
Add New Account target SHALL state that a documented navigation path naming a tile
absent from the Add New Account provider list is Coverage evidence, not a new target.

#### Scenario: Index specs use Coverage not feature

- **GIVEN** a change authors documentation-ingest requirements about surfaces an
  Add New Account target unlocks
- **WHEN** it names those surfaces
- **THEN** it MUST use Coverage rather than feature, scanning surface, module, or
  optional scope

#### Scenario: Missing tile is not read as a target

- **GIVEN** the glossary entry for Add New Account target
- **WHEN** a reader uses that term after this change archives
- **THEN** the Notes MUST say the Add New Account provider list decides the tile
  label
- **AND** the Notes MUST say a documented path to a missing tile is Coverage of the
  real target, not a new Add New Account target

## Term entries

### Term: Coverage
**Context**: documentation-ingest
**Definition**: An operator-named Entro surface that one Add New Account target can unlock after connect, evidenced by a GitBook section that resolves to that target and is not the target's core onboarding, permissions, or troubleshooting docs.
**Aliases**: none
**Notes**: Always a child of one target row. SharePoint / OneDrive and Copilot Studio are Coverages of Microsoft Ecosystem. Git clone scanning is not a Coverage; it spans several targets and is documented at product level. A Graph permission-group heading is Integration prep, not a Coverage. Not a setup method, not an authentication method, not an Add New Account target.

---

## MODIFIED Requirements

### Requirement: Add New Account target terms

The glossary SHALL define Add New Account target, Setup method, Authentication method,
Connector requirement, and Requirement evidence with the definitions in Term entries below.

#### Scenario: Index specs distinguish target from method

- **GIVEN** a change authors documentation-ingest requirements about the Integration index
- **WHEN** it names a row, a route through Integration prep, or a credential type
- **THEN** it MUST use Add New Account target, Setup method, and Authentication method rather than calling all three a variant

#### Scenario: Connector claims name their evidence

- **GIVEN** a spec or index row states whether a connection form needs a Worker Group
- **WHEN** the statement is recorded
- **THEN** it MUST use Connector requirement for the value and Requirement evidence for its citation

## Term entries

### Term: Add New Account target
**Context**: documentation-ingest
**Definition**: The selection in Entro's Add New Account flow that determines which connection form the operator sees — a tile on its own, or an explicit in-form target choice under a tile such as `GitHub Cloud - New`, `BitBucket Data Center`, or `Slack Enterprise Grid App`.
**Aliases**: target
**Notes**: One row in `integrations.json` is exactly one target, identified by the tile label and the in-form selection together. Take the tile label from the Add New Account provider list. When a GitBook page documents a navigation path, use that label only if the named tile exists on the provider list; a path that names a missing tile is Coverage of the target those pages actually connect through, not a new row. Not a setup method, not an authentication method, not a checkbox inside a form, not a Coverage.
