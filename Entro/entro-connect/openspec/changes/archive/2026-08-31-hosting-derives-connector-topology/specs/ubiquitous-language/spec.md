<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Hosting terms

The glossary SHALL define Hosting with the definition in Term entries below.
Notes MUST state that Connector deployment is derived from Hosting and MUST NOT
be stored on an Integration index row.

#### Scenario: Index specs name hosting not connector type

- **GIVEN** a change authors documentation-ingest requirements about the Integration index
- **WHEN** it describes how an operator picks Docker Compose, Kubernetes Helm, or SaaS Perimeter
- **THEN** it MUST use Hosting for the row attribute and Connector deployment for the derived topology
- **AND** it MUST NOT require a stored topology list on the row

---

## MODIFIED Requirements

### Requirement: Add New Account target terms

The glossary SHALL define Add New Account target, Setup method, Authentication method,
and Hosting with the definitions in Term entries below.

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
**Notes**: One row in `integrations.json` is exactly one target, identified by the tile label and the in-form selection together. Take the tile label from the Add New Account provider list. When a GitBook page documents a navigation path, use that label only if the named tile exists on the provider list; a path that names a missing tile is Coverage of the target those pages actually connect through, not a new row. A connector is always required; the row records Hosting, not Connector deployment. Not a setup method, not an authentication method, not a checkbox inside a form, not a Coverage.

### Term: Hosting
**Context**: documentation-ingest
**Definition**: Whether an Add New Account target's connection endpoint is internet-reachable (`public`), inside the customer's private network (`self-hosted`), or chosen by the operator inside the connection form (`operator-selected`).
**Aliases**: reachability, instance type
**Notes**: One value per row. GitLab and n8n are `operator-selected` because their forms document both cloud and self-hosted. Not Connector deployment, not category, not a stored topology list.

### Term: Connector deployment
**Context**: documentation-ingest
**Definition**: How an Entro Connector runs when an Integration requires one: Entro cloud (default managed connector), SaaS perimeter (static-IP connector), self-managed Docker Compose, or self-managed Kubernetes (Helm).
**Aliases**: worker group deployment, connector topology
**Notes**: Derived from Hosting: `public` → SaaS Perimeter; `self-hosted` → Docker Compose or Kubernetes Helm (Helm preferred when scanning is cluster-native); `operator-selected` follows the form choice. Documented in `entro-connector/` pages. Not a JSON key on the target row. Entro cloud remains a product-level page, not a hosting mapping.
