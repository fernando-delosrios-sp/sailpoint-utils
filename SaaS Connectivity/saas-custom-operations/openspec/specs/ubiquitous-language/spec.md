# Ubiquitous Language

Shared domain vocabulary for this project. All specs, design docs, code identifiers,
and user-facing copy MUST align with the terms defined here.

## ADDED Requirements

### Requirement: Glossary maintenance

The project SHALL maintain an authoritative glossary of domain terms with unambiguous
definitions, preferred spellings, and known aliases.

#### Scenario: New term introduced in a change

- **GIVEN** a change proposal introduces a new domain concept or renames an existing one
- **WHEN** the change is approved for implementation
- **THEN** the term MUST be added or updated in this spec before the change archives

#### Scenario: Term used in a spec

- **GIVEN** a capability spec references a domain noun or verb
- **WHEN** the term is not yet defined in this glossary
- **THEN** the author MUST add the definition here or reuse an existing term instead

### Requirement: Consistent naming

Implementation artifacts (types, functions, API fields, database columns, UI labels)
SHALL use glossary terms verbatim unless a documented alias applies.

#### Scenario: Code review against glossary

- **GIVEN** an implementation uses a domain label visible to other systems or users
- **WHEN** the label differs from the glossary preferred spelling without an alias entry
- **THEN** the implementation MUST be corrected or the glossary MUST be updated first

### Requirement: Bounded context boundaries

When the same word means different things in different areas, each meaning MUST be
listed as a separate entry with its bounded context noted.

#### Scenario: Homonym disambiguation

- **GIVEN** two subsystems use the same word with different meanings
- **WHEN** both meanings appear in specs or code
- **THEN** each meaning MUST have its own glossary entry naming the bounded context

### Requirement: SoD form HTML vocabulary

The project glossary SHALL include terms for unified SoD remediation form HTML styling introduced by the sod-form-html library and consuming operations.

#### Scenario: SoD form HTML term

- **GIVEN** specs or code refer to shared HTML builders for SoD remediation forms
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **SoD form HTML** as HTML string assembly for ISC form DESCRIPTION content under `src/lib/sod-form-html/`

#### Scenario: Outcome panel term

- **GIVEN** specs describe green or red group column backgrounds after side selection
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **outcome panel** as the keep/remove fate wrapper applied after remediation side selection

#### Scenario: Side HTML variant term

- **GIVEN** specs describe pre-rendered group column HTML strings
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **side HTML variant** as one of `plain`, `asKept`, or `asRemoved` for a policy side at form launch

#### Scenario: Type tag term

- **GIVEN** specs describe inline access kind pills on list lines
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **type tag** as the pill span denoting role, access profile, or entitlement on a line

## Term entries

### Term: SoD form HTML
**Context**: sod-form-html
**Definition**: HTML string assembly for ISC form DESCRIPTION content under `src/lib/sod-form-html/`.
**Aliases**: none
**Notes**: Shared by `custom:sod-remediation` and `custom:access-sod-remediation`.

### Term: Outcome panel
**Context**: sod-form-html
**Definition**: The keep/remove fate wrapper applied after remediation side selection, using green for kept and red for removed.
**Aliases**: none
**Notes**: Appears only in `asKept` and `asRemoved` side HTML variants.

### Term: Side HTML variant
**Context**: sod-form-html
**Definition**: One of `plain`, `asKept`, or `asRemoved` for a policy side at form launch.
**Aliases**: none
**Notes**: Pre-rendered into formInput STRING fields; seed formConditions swap visibility on selection.

### Term: Type tag
**Context**: sod-form-html
**Definition**: The pill span denoting role, access profile, or entitlement on a line.
**Aliases**: none
**Notes**: Rendered via `renderTypeTag`; labels are lowercase (`role`, `access profile`, `entitlement`).

<!-- Add terms using this pattern:

### Term: <Preferred Name>
**Context**: <bounded context or "global">
**Definition**: <one or two sentences>
**Aliases**: <comma-separated alternatives, or "none">
**Notes**: <optional examples, anti-patterns, related terms>

-->
