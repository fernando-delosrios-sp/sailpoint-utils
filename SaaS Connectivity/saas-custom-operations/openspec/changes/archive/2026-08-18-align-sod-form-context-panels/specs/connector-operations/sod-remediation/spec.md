## ADDED Requirements

### Requirement: SOD remediation context panel layout

The bundled sod-remediation form seed SHALL present a single upper context panel DESCRIPTION interpolating `situationSummaryHtml`. The panel SHALL use user-facing section copy structured as “What we found” and “What we need from you”. The seed SHALL NOT include a separate static identity/policy/violation metadata DESCRIPTION that duplicates content from `situationSummaryHtml`.

#### Scenario: Single ctx-summary element

- **GIVEN** the bundled sod-remediation seed template
- **WHEN** the context section is inspected
- **THEN** exactly one DESCRIPTION element SHALL interpolate `{{$.form.input.situationSummaryHtml}}`
- **AND** the seed SHALL NOT define element id `ctx-identity`

#### Scenario: User-facing section label

- **GIVEN** the bundled sod-remediation seed context section
- **WHEN** the section label is inspected
- **THEN** it SHALL NOT contain the phrase `policy violation detection`

#### Scenario: Call to action in summary

- **WHEN** `situationSummaryHtml` is assembled for a violation with compensating controls available
- **THEN** the “What we need from you” block SHALL instruct the recipient to choose Correct or Mitigate and select a remediation side

---

## MODIFIED Requirements

### Requirement: Situation summary HTML format

The sod-remediation operation SHALL build `sod-remediation:form-email-body` as HTML suitable for workflow email bodies. Form launch `situationSummaryHtml` SHALL reuse the shared situation summary HTML without the remediation form link and SHALL append a single emoji legend footer when access-path lists are included. Violation-derived dynamic text SHALL be HTML-escaped and SHALL NOT embed unescaped user-controlled markup. When UI origin is available from `apiUrl`, `situationSummaryHtml` and linked group column line names SHALL wrap entity display names in ISC admin UI links.

#### Scenario: Email-oriented HTML structure

- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** operation output `sod-remediation:form-email-body` SHALL include a compact summary suitable for workflow email without entity admin deep links
- **AND** persisted body SHALL retain the remediation form link using the existing compact format

#### Scenario: In-form context panel structure

- **WHEN** `situationSummaryHtml` is assembled
- **THEN** it SHALL include a top-level heading with ⚠️ signposting
- **AND** SHALL include “What we found” and “What we need from you” blocks
- **AND** SHALL include grouped access-path lists for Group A and Group B when paths exist

#### Scenario: Dynamic values escaped

- **WHEN** `custom:sod-remediation` assembles the situation summary
- **THEN** violation-derived text in `situationSummaryHtml` SHALL escape `&`, `<`, `>`, and `"` characters
- **AND** persisted `sod-remediation:form-email-body` SHALL escape the same characters in dynamic text

#### Scenario: Form input reuses operation summary without email-only link

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** `situationSummaryHtml` SHALL equal the shared situation summary HTML without the remediation form link
- **AND** persisted output `sod-remediation:form-email-body` SHALL equal that same compact HTML plus the remediation form link

#### Scenario: Seed interpolates summary without extra wrapper

- **GIVEN** the bundled SOD remediation seed template
- **WHEN** the ctx-summary DESCRIPTION element is inspected
- **THEN** its `description` SHALL be exactly `{{$.form.input.situationSummaryHtml}}` without an additional surrounding wrapper element

#### Scenario: Situation summary includes emoji legend

- **WHEN** `situationSummaryHtml` is assembled
- **THEN** it SHALL append one emoji legend footer decoding revocability, keep recommendation, and privileged icons
- **AND** group column HTML variants SHALL NOT include the legend footer

#### Scenario: Linked identity and policy in summary

- **GIVEN** invoke provides `apiUrl` for tenant UI origin resolution
- **WHEN** `situationSummaryHtml` is assembled
- **THEN** the identity display name SHALL link to the identity admin UI route
- **AND** the policy display name SHALL link to the SoD policy admin UI route

#### Scenario: Violation id plain with violations list link

- **GIVEN** UI origin is available
- **WHEN** `situationSummaryHtml` is assembled
- **THEN** the violation id SHALL appear as plain escaped text
- **AND** a separate anchor labeled for viewing SOD violations SHALL link to `{uiOrigin}/ui/sod/violations`
- **AND** the violation id SHALL NOT itself be the href target

#### Scenario: Offline summary omits admin links

- **GIVEN** invoke runs without `apiUrl`
- **WHEN** `situationSummaryHtml` is assembled
- **THEN** entity names SHALL render as plain escaped text without `<a href=` anchors

#### Scenario: In-form summary allows quoted link attributes

- **WHEN** `situationSummaryHtml` includes ISC admin links
- **THEN** anchors SHALL use quoted `href` attributes
- **AND** SHALL include `target="_blank"` and `rel="noopener noreferrer"`

---

## MODIFIED Requirements

### Requirement: Revocability HTML display with emojis

The sod-remediation operation SHALL render access path annotations in HTML using space-separated UTF-8 emoji icon suffixes on each line in group column form input and in operation `sod-remediation:form-email-body` output. Lines SHALL use shared type tags for access kind. When UI origin is available, access path display names in group column HTML SHALL link to the corresponding ISC admin UI routes. Inline revocability and keep recommendation text labels SHALL NOT appear on lines; meanings SHALL be conveyed by the situation summary legend footer only.

#### Scenario: Group column HTML form input

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** each group side SHALL produce plain, asKept, and asRemoved HTML variants in `groupColumnsHtmlPlain`, `groupColumnsHtmlWhenGroupARemoved`, `groupColumnsHtmlWhenGroupBRemoved`, and B-side equivalents
- **AND** plain variants SHALL contain type tags and icon suffixes without outcome panel wrappers
- **AND** asKept and asRemoved variants SHALL wrap the same line content in green and red outcome panels respectively
- **AND** the bundled seed SHALL render those keys in conditional DESCRIPTION elements for group A and group B columns

#### Scenario: Group column HTML form input variants

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** formInput SHALL include group column HTML STRING fields covering plain and outcome variants for each side
- **AND** seed formConditions SHALL swap visible DESCRIPTION elements when `remediationSide` changes

#### Scenario: Icon suffixes on lines

- **GIVEN** a revocable access path line with keep recommendation `YES`
- **WHEN** HTML is rendered
- **THEN** the line SHALL include space-separated `⭐` and `✅` icon suffixes
- **AND** SHALL NOT include inline text `Revocable` or `Recommended to keep` on the line

#### Scenario: Linked path line names when online

- **GIVEN** UI origin is available and a path line has id and type `ENTITLEMENT`
- **WHEN** group column HTML is rendered
- **THEN** the entitlement display name SHALL be wrapped in an entitlement admin UI link

#### Scenario: Email summary parity

- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** persisted output `sod-remediation:form-email-body` SHALL include the same access path icon suffixes and side correction hint as the group column HTML line content without entity admin deep links
- **AND** `situationSummaryHtml` SHALL additionally include the emoji legend footer
