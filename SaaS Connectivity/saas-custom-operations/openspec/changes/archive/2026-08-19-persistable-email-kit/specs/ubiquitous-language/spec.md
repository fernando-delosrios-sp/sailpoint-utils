## ADDED Requirements

### Requirement: Persistable email body term

The glossary SHALL define **persistable email body** as a compact HTML string intended for DelimitedFile/STRING account attributes and ISC workflow Send Email bodies, bounded by `ISC_STRING_ATTRIBUTE_MAX_LENGTH` (256).

#### Scenario: Preferred term for compact workflow email HTML

- **GIVEN** documentation refers to HTML stored on a result account for workflow email delivery
- **WHEN** distinguishing it from in-form DESCRIPTION HTML
- **THEN** the preferred term SHALL be **persistable email body**
- **AND** SHALL NOT call that content SoD form HTML or situation summary panel without qualification

### Requirement: Unquoted href CTA term

The glossary SHALL define **unquoted href CTA** as an HTML anchor whose `href` value is not wrapped in quotes, kept DelimitedFile/`provisionAsCsv`-safe when URLs contain no spaces.

#### Scenario: Preferred spelling for form email links

- **GIVEN** specs describe the remediation or reminder link inside a persistable email body
- **WHEN** naming the link construction convention
- **THEN** the preferred term SHALL be **unquoted href CTA**
- **AND** normative examples SHALL NOT require quoted `href="..."` attributes
