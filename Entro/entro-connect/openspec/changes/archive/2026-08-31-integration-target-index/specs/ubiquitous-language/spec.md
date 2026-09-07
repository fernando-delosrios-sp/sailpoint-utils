<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

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
**Notes**: One row in `integrations.json` is exactly one target, identified by the tile label and the in-form selection together. Read the tile label from the documented Add New Account navigation path, not from the documentation section name. Not a setup method, not an authentication method, not a checkbox inside a form.

### Term: Setup method
**Context**: documentation-ingest
**Definition**: A documented route for performing Integration prep for one target, such as a CloudFormation stack versus a hand-built IAM role, or automated PowerShell versus manual app registration.
**Aliases**: onboarding method
**Notes**: A setup method never changes the Entro connection form, so it is an attribute of a row and never a row itself. Two setup methods for one target MUST NOT be able to disagree about that target's connector requirement.

### Term: Authentication method
**Context**: documentation-ingest
**Definition**: The credential type a target's connection form accepts, chosen inside that form — Service Account key versus Workload Identity Federation, fine-grained versus classic token.
**Aliases**: none
**Notes**: An attribute of a row, never a row of its own.

### Term: Connector requirement
**Context**: documentation-ingest
**Definition**: Whether an Add New Account target's connection form requires the operator to select a Worker Group (Connector). One of `required`, `not-required`, or `unknown`.
**Aliases**: none
**Notes**: A property of the target, because it is a property of the form. Distinct from Connector deployment, which describes how an Entro Connector runs.

### Term: Requirement evidence
**Context**: documentation-ingest
**Definition**: The citation that justifies a row's connector requirement — an ingested documentation page plus the form field label or complete field list on that page which settles the question.
**Aliases**: none
**Notes**: `required` is evidenced by a documented Worker Group field; `not-required` by a complete documented field list that omits it. A page that simply does not mention the field is not evidence and leaves the requirement `unknown`. Cite pages, not line numbers, which rot on re-ingest.

### Term: Integration variant
**Context**: documentation-ingest
**Definition**: Superseded — use Add New Account target for a row in the Integration index, Setup method for a route through Integration prep, and Authentication method for a credential type.
**Aliases**: deployment variant, onboarding variant
**Notes**: The term was applied to Add New Account targets, setup methods, authentication methods, and form checkboxes alike. That conflation let two rows describe one connection form with contradictory connector requirements, so the term is retired rather than redefined. Existing text saying "each variant MAY have different connector requirements" is replaced by: connector requirement is a property of the target.

---

## MODIFIED Requirements

### Requirement: Glossary maintenance

The project SHALL maintain an authoritative glossary of domain terms with unambiguous
definitions, preferred spellings, and known aliases. When a term is superseded by a more
precise one, the glossary SHALL record the superseding term rather than silently broadening
the old definition.

#### Scenario: New term introduced in a change

- **GIVEN** a change proposal introduces a new domain concept or renames an existing one
- **WHEN** the change is approved for implementation
- **THEN** the term MUST be added or updated in this spec before the change archives

#### Scenario: Term used in a spec

- **GIVEN** a capability spec references a domain noun or verb
- **WHEN** the term is not yet defined in this glossary
- **THEN** the author MUST add the definition here or reuse an existing term instead

#### Scenario: Term superseded by a more precise one

- **GIVEN** an existing term is used for several distinct concepts in implementation artifacts
- **WHEN** a change introduces precise terms for those concepts
- **THEN** the old term MUST be marked as superseded, naming the terms that replace it
