## ADDED Requirements

### Requirement: SoD form context panel vocabulary

The project glossary SHALL include terms for unified SoD remediation form upper-panel content and ISC admin deep linking introduced by aligned context panels.

#### Scenario: Context panel term

- **GIVEN** specs or README describe the upper form section explaining the conflict and required recipient action
- **WHEN** normative text names that section
- **THEN** it SHALL define **context panel** as the “What we found / What we need from you” upper DESCRIPTION content
- **AND** SHALL distinguish it from group column preview sections

#### Scenario: ISC UI link term

- **GIVEN** specs or code render anchors to ISC admin routes from form HTML
- **WHEN** normative text names those anchors
- **THEN** it SHALL define **ISC UI link** as an admin UI anchor built from invoke `apiUrl` without hardcoded domains

#### Scenario: UI origin term

- **GIVEN** specs describe deriving the tenant UI base URL from loopback `apiUrl`
- **WHEN** normative text names that base URL
- **THEN** it SHALL define **UI origin** as the protocol and host used to prefix ISC admin UI paths
