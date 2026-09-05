<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Connector requirement terms are superseded

The glossary SHALL mark Connector requirement and Requirement evidence as superseded.
Notes MUST state that a connector is always required for an Add New Account target and
that runtime topology is Connector deployment, documented at product level.

#### Scenario: Index specs do not use Connector requirement

- **GIVEN** a change authors documentation-ingest requirements about the Integration index
- **WHEN** it describes a target row
- **THEN** it MUST NOT require `connectorRequirement` or `connectorEvidence`
- **AND** it MUST NOT use Connector requirement or Requirement evidence as live terms

---

## MODIFIED Requirements

### Requirement: Add New Account target terms

The glossary SHALL define Add New Account target, Setup method, and Authentication method
with the definitions in Term entries below.

#### Scenario: Index specs distinguish target from method

- **GIVEN** a change authors documentation-ingest requirements about the Integration index
- **WHEN** it names a row, a route through Integration prep, or a credential type
- **THEN** it MUST use Add New Account target, Setup method, and Authentication method rather than calling all three a variant

#### Scenario: Connector claims name their evidence

- **GIVEN** a spec or index row would have stated whether a connection form needs a Worker Group
- **WHEN** the Integration index is written
- **THEN** that row MUST NOT use Connector requirement or Requirement evidence
- **AND** it MUST NOT carry `connectorRequirement` or `connectorEvidence`

## Term entries

### Term: Add New Account target
**Context**: documentation-ingest
**Definition**: The selection in Entro's Add New Account flow that determines which connection form the operator sees — a tile on its own, or an explicit in-form target choice under a tile such as `GitHub Cloud - New`, `BitBucket Data Center`, or `Slack Enterprise Grid App`.
**Aliases**: target
**Notes**: One row in `integrations.json` is exactly one target, identified by the tile label and the in-form selection together. Take the tile label from the Add New Account provider list. When a GitBook page documents a navigation path, use that label only if the named tile exists on the provider list; a path that names a missing tile is Coverage of the target those pages actually connect through, not a new row. A connector is always required; the row does not record connector requirement. Not a setup method, not an authentication method, not a checkbox inside a form, not a Coverage.

### Term: Setup method
**Context**: documentation-ingest
**Definition**: A documented route for performing Integration prep for one target, such as a CloudFormation stack versus a hand-built IAM role, or automated PowerShell versus manual app registration.
**Aliases**: onboarding method
**Notes**: A setup method never changes the Entro connection form, so it is an attribute of a row and never a row itself.

### Term: Authentication method
**Context**: documentation-ingest
**Definition**: The credential type a target's connection form accepts, chosen inside that form — Service Account key versus Workload Identity Federation, fine-grained versus classic token.
**Aliases**: none
**Notes**: An attribute of a row, never a row of its own.

### Term: Connector requirement
**Context**: documentation-ingest
**Definition**: Superseded — a connector is always required for an Add New Account target. Do not record `required`, `not-required`, or `unknown` on the Integration index. Runtime topology is Connector deployment.
**Aliases**: none
**Notes**: Previously meant whether the connection form had a Worker Group field. That mixed form fields with Entro Connector deployment. Worker Group, if documented, is a connection-detail for later prep.

### Term: Requirement evidence
**Context**: documentation-ingest
**Definition**: Superseded — the Integration index no longer cites a page to justify a connector requirement.
**Aliases**: none
**Notes**: Previously a page plus quote (Worker Group present or omitted). Dropped with Connector requirement.

### Term: Integration variant
**Context**: documentation-ingest
**Definition**: Superseded — use Add New Account target for a row in the Integration index, Setup method for a route through Integration prep, and Authentication method for a credential type.
**Aliases**: deployment variant, onboarding variant
**Notes**: The term was applied to Add New Account targets, setup methods, authentication methods, and form checkboxes alike. That conflation is retired rather than redefined.
