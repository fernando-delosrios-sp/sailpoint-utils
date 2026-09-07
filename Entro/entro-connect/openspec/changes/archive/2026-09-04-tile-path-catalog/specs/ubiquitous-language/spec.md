## ADDED Requirements

### Requirement: Tile and Integration path terms

The glossary SHALL define Integration, Integration path, Optional capability, and
Capture required with the definitions in the Term entries below.

#### Scenario: Catalog and Connect specs use tile-path vocabulary

- **GIVEN** a spec describes catalog identity, a mutually exclusive connection-form choice, an additional feature, or an uncaptured tile
- **WHEN** it names that concept
- **THEN** it MUST use Integration, Integration path, Optional capability, or Capture required respectively
- **AND** it MUST NOT use Add New Account target, Setup method, Authentication method, or Coverage as Lock dimensions

## MODIFIED Requirements

### Requirement: Retired Lock-dimension terms

The glossary SHALL mark Add New Account target, Setup method, Authentication
method, and Coverage as superseded Lock dimensions and name their replacements.

#### Scenario: Existing Lock vocabulary is superseded

- **GIVEN** an artifact describes the choices confirmed during Connect Lock
- **WHEN** it names the catalog row or mutually exclusive form route
- **THEN** it MUST use Integration and Integration path
- **AND** optional features MUST be named Optional capabilities and consented during Prep

## Term entries

### Term: Integration

**Context**: documentation-ingest, integration-automation
**Definition**: One exact Entro Select Provider tile label. The catalog row identity.
**Aliases**: provider tile, Select Provider tile
**Notes**: Not a documentation section, not a setup route, not a Coverage name.

### Term: Integration path

**Context**: documentation-ingest, integration-automation
**Definition**: A mutually exclusive connection-form choice visible on an Integration tile. Owns prep, tools, connection fields, operator inputs, and Typed actions for that route. A singleton path is implicit and needs no Lock gate.
**Aliases**: connection path, preparation route (when visible on the form)
**Notes**: Replaces Add New Account target selection, Setup method, and Authentication method as Lock dimensions.

### Term: Optional capability

**Context**: integration-automation, integration-prep
**Definition**: A non-core surface or feature the operator may enable after Lock. Additional instructions or Typed actions run only after just-in-time operator consent, including in automated mode.
**Aliases**: optional surface, optional feature
**Notes**: Not selected at Lock. Differs from mandatory baseline capabilities on the tile or path.

### Term: Capture required

**Context**: documentation-ingest, integration-automation
**Definition**: A tile row reserved in the catalog before its connection form and Integration paths are evidenced. Connect stops before Lock.
**Aliases**: stub tile, uncaptured tile
**Notes**: Must not invent paths, fields, or Typed actions.

### Term: Add New Account target

**Context**: documentation-ingest
**Definition**: Superseded — use Integration for the Select Provider tile and Integration path for the visible form choice.
**Aliases**: target selection, in-form target
**Notes**: Retired at Lock; historical docs may still mention the phrase.

### Term: Setup method

**Context**: documentation-ingest
**Definition**: Superseded as a Lock dimension — when visible on the Entro form, it is an Integration path; when only in documentation, it remains preparation guidance on the locked path.
**Aliases**: onboarding route
**Notes**: Fork census may still cite documented setup pages.

### Term: Authentication method

**Context**: documentation-ingest
**Definition**: Superseded as a Lock dimension — when visible on the Entro form, it is an Integration path or part of a compound path name.
**Aliases**: credential type
**Notes**: Connection field maps bind to the locked path.

### Term: Coverage

**Context**: documentation-ingest, integration-automation
**Definition**: Superseded as a Lock dimension — use Optional capability for operator-consented additional surfaces. Mandatory/core behavior stays on the Integration or Integration path baseline.
**Aliases**: surface, optional coverage
**Notes**: Historical specs used Coverage for SharePoint; SharePoint is now its own Integration tile.
