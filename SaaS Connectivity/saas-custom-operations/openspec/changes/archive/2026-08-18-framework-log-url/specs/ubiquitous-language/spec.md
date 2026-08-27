## ADDED Requirements

### Requirement: logUrl term

The glossary SHALL define logUrl as the optional invoke-config URL that receives structured JSON log events from the custom-operation framework when set.

#### Scenario: logUrl used in specs and config

- **GIVEN** documentation or specs refer to external log delivery configuration
- **WHEN** naming the invoke config field or related types
- **THEN** the preferred spelling SHALL be logUrl
- **AND** aliases log endpoint or remote logger URL SHALL NOT be used in normative text without an alias entry

---

### Term: logUrl

**Context**: custom-operation-framework / connector-config

**Definition**: Optional invoke-config string URL. When non-empty, the framework POSTs one JSON log event per logger call to that URL in addition to writing human-readable lines to stdout.

**Aliases**: none

**Notes**: Not declared in connector-spec.json sourceConfig in v1; supplied at invoke time via config.logUrl on workflow or spcx payloads.

---
