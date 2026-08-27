## ADDED Requirements

### Requirement: Persistable email shared library

The connector SHALL provide shared persistable email HTML builders under `src/lib/persistable-email/`. The library SHALL assemble compact HTML strings suitable for ISC STRING account attributes and workflow Send Email bodies. It SHALL NOT invoke ISC APIs, create form instances, or encode operation persist key names.

#### Scenario: HTML escape

- **GIVEN** text containing `&`, `<`, `>`, or `"`
- **WHEN** `escapeHtml` is applied
- **THEN** those characters SHALL be replaced with HTML entities

#### Scenario: Truncate escaped text with ellipsis

- **GIVEN** an escaped string longer than the requested max length
- **WHEN** truncate-with-ellipsis is applied with max length greater than 1
- **THEN** the result SHALL be at most max length characters and SHALL end with `…` when truncated

#### Scenario: Unquoted href CTA

- **GIVEN** a form or approval URL and a link label
- **WHEN** the unquoted href CTA helper is invoked
- **THEN** the output SHALL be an `<a>` tag whose `href` attribute value is HTML-escaped and NOT wrapped in quotes
- **AND** the label SHALL be HTML-escaped

#### Scenario: Fit within STRING max length

- **GIVEN** a render function with two or more variable name slots and a max length of `ISC_STRING_ATTRIBUTE_MAX_LENGTH`
- **WHEN** the fitted HTML would exceed the limit with full names
- **THEN** the library SHALL shorten escaped name slots so the rendered HTML length is ≤ max length
- **AND** SHALL preserve the CTA segment produced by the render function

#### Scenario: Optional suffix dropped when over budget

- **GIVEN** a render function that can include an optional suffix segment
- **WHEN** the full render with suffix exceeds max length but the render without suffix fits (after name fitting if needed)
- **THEN** the library SHALL return HTML without that optional suffix

#### Scenario: No ISC side effects

- **GIVEN** any persistable-email helper
- **WHEN** it is invoked
- **THEN** it SHALL NOT call ISC APIs or Forms APIs

---

## MODIFIED Requirements

<!-- none for sod-form-html in this delta file; see sod-form-html/spec.md -->
