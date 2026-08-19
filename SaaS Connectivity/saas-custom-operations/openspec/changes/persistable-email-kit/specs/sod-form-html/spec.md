## MODIFIED Requirements

### Requirement: SoD form HTML shared library

The connector SHALL provide shared SoD remediation form HTML builders under `src/lib/sod-form-html/`. The library SHALL assemble HTML strings for ISC form DESCRIPTION interpolation and SHALL NOT invoke ISC APIs or encode operation persist logic. Compact workflow **persistable email body** HTML SHALL be assembled via `src/lib/persistable-email/` rather than duplicated inside this library; `escapeHtml` MAY be re-exported from persistable-email for convenience.

#### Scenario: Type tag rendering

- **GIVEN** an access object kind of `ROLE`, `ACCESS_PROFILE`, or `ENTITLEMENT`
- **WHEN** a line is rendered through the shared library
- **THEN** the output SHALL include an inline pill-style span identifying the kind
- **AND** SHALL NOT prefix the display name with `Role:` or `Access Profile:` text

#### Scenario: Outcome panel wrapping

- **GIVEN** list HTML content and outcome `keep` or `remove`
- **WHEN** the library wraps content in an outcome panel
- **THEN** the output SHALL use a green background for `keep` and a red background for `remove`
- **AND** SHALL include a left accent border consistent with the outcome color

#### Scenario: Plain variant has no panel

- **GIVEN** list HTML content and variant `plain`
- **WHEN** the library assembles a side HTML variant
- **THEN** the output SHALL NOT include an outcome panel background wrapper

#### Scenario: Icon suffix formatting

- **GIVEN** zero or more emoji markers for a line
- **WHEN** the library formats an icon suffix
- **THEN** multiple markers SHALL be space-separated (e.g. `⭐ ✅`)
- **AND** SHALL NOT concatenate markers without intervening spaces

#### Scenario: Emoji legend block

- **WHEN** `renderEmojiLegend` is invoked
- **THEN** the output SHALL decode revocability, keep recommendation, and privileged icons with explanatory text

#### Scenario: Boundary with persistable email

- **GIVEN** a caller needs compact HTML for a workflow Send Email body bounded by STRING max length
- **WHEN** choosing a shared library
- **THEN** the caller SHALL use `persistable-email` helpers
- **AND** SHALL NOT treat `sod-form-html` as the home for fit-to-256 email body construction
