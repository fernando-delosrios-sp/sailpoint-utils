## ADDED Requirements

### Requirement: Group column outcome panel variants

The sod-remediation operation SHALL pre-render three HTML variants per policy side at form launch and populate corresponding formInput STRING fields. Outcome panels SHALL appear only after the recipient selects a remediation side.

#### Scenario: Six group HTML formInput fields

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** formInput SHALL include `groupAContentsHtml`, `groupAContentsHtmlAsKept`, `groupAContentsHtmlAsRemoved`, `groupBContentsHtml`, `groupBContentsHtmlAsKept`, and `groupBContentsHtmlAsRemoved`
- **AND** the plain variants SHALL NOT include outcome panel wrappers

#### Scenario: Plain variants shown before selection

- **GIVEN** the bundled seed form definition with formConditions for group column DESCRIPTION elements
- **WHEN** the recipient has not selected `remediationSide`
- **THEN** the seed SHALL show plain `groupAContentsHtml` and `groupBContentsHtml` DESCRIPTION elements
- **AND** SHALL NOT show `AsKept` or `AsRemoved` variants

#### Scenario: Outcome variants shown after Group A selection

- **GIVEN** the recipient selects `remediationSide` value `groupA`
- **WHEN** formConditions evaluate
- **THEN** Group A column SHALL show `groupAContentsHtmlAsRemoved` with red outcome panel styling
- **AND** Group B column SHALL show `groupBContentsHtmlAsKept` with green outcome panel styling
- **AND** plain variants SHALL be hidden

#### Scenario: Outcome variants shown after Group B selection

- **GIVEN** the recipient selects `remediationSide` value `groupB`
- **WHEN** formConditions evaluate
- **THEN** Group B column SHALL show `groupBContentsHtmlAsRemoved` with red outcome panel styling
- **AND** Group A column SHALL show `groupAContentsHtmlAsKept` with green outcome panel styling

#### Scenario: Flat horizontal list topology preserved

- **WHEN** group column HTML is rendered for any variant
- **THEN** access paths on each side SHALL render as a flat unordered list without nested access-profile grouping

---

## MODIFIED Requirements

### Requirement: Situation summary HTML format

The sod-remediation operation SHALL build `sod-remediation:situation-summary` as HTML suitable for workflow email bodies. The same HTML SHALL populate `situationSummaryHtml` formInput for in-form DESCRIPTION rendering. Violation-derived dynamic text SHALL be HTML-escaped and SHALL NOT embed unescaped user-controlled markup. The in-form `situationSummaryHtml` SHALL append a single emoji legend footer decoding icon suffix meanings.

#### Scenario: Email-oriented HTML structure

- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** operation output `sod-remediation:situation-summary` SHALL include a top-level heading, labeled identity/policy/violation fields, grouped access-path lists, and an optional note when no compensating controls exist
- **AND** SHALL use semantic HTML elements such as `h2`, `h3`, `p`, `strong`, `ul`, `li`, and `em`

#### Scenario: Dynamic values escaped

- **WHEN** `custom:sod-remediation` assembles the situation summary
- **THEN** violation-derived text in both `sod-remediation:situation-summary` and `situationSummaryHtml` SHALL escape `&`, `<`, `>`, and `"` characters

#### Scenario: Form input reuses operation summary without email-only link

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** `situationSummaryHtml` SHALL equal the shared situation summary HTML without the remediation form link
- **AND** persisted output `sod-remediation:situation-summary` SHALL equal that same HTML plus the remediation form link

#### Scenario: Seed interpolates summary without extra wrapper

- **GIVEN** the bundled SOD remediation seed template
- **WHEN** the ctx-summary DESCRIPTION element is inspected
- **THEN** its `description` SHALL be exactly `{{$.form.input.situationSummaryHtml}}` without an additional surrounding wrapper element

#### Scenario: Situation summary includes emoji legend

- **WHEN** `situationSummaryHtml` is assembled
- **THEN** it SHALL append one emoji legend footer decoding revocability, keep recommendation, and privileged icons
- **AND** group column HTML variants SHALL NOT include the legend footer

### Requirement: ISC keep recommendation annotation

The sod-remediation operation SHALL fetch ISC keep recommendations for each resolved access path item on the violation target identity at launch using the Recommendations API. Items whose recommendation is `YES` SHALL be annotated for display as recommended to keep using a keep star icon suffix. Items whose recommendation is `MAYBE`, `NO`, or `NOT_FOUND` SHALL NOT receive a keep star.

#### Scenario: Batch keep recommendations at launch

- **GIVEN** resolved access paths for Group A and Group B
- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** the handler SHALL request keep recommendations for all unique access items across both sides in a single batch call
- **AND** SHALL map each response back to the corresponding access path line by item id and type

#### Scenario: YES shows keep star

- **GIVEN** the Recommendations API returns `YES` for a role on Group B
- **WHEN** form input and situation summary HTML are rendered
- **THEN** that role line SHALL include a keep star icon suffix without inline explanatory text on the line
- **AND** the situation summary legend SHALL decode the keep star meaning
- **AND** SHALL NOT include a connector revoke recommendation star

#### Scenario: MAYBE does not show keep star

- **GIVEN** the Recommendations API returns `MAYBE` for an entitlement
- **WHEN** HTML is rendered
- **THEN** that line SHALL NOT include a keep star
- **AND** SHALL NOT count toward side correction logic as a keep recommendation

#### Scenario: Recommendations API failure degrades silently

- **GIVEN** the Recommendations API call fails or times out
- **WHEN** `custom:sod-remediation` completes launch
- **THEN** the handler SHALL proceed without keep stars or side correction hint
- **AND** SHALL NOT surface an error message to the form recipient

### Requirement: Privileged access indicator

The sod-remediation operation SHALL annotate entitlement access path lines with a privileged indicator when entitlement metadata marks the entitlement as privileged.

#### Scenario: Privileged entitlement badge

- **GIVEN** entitlement metadata indicates an entitlement is privileged
- **WHEN** access path HTML is rendered
- **THEN** that entitlement line SHALL include a privileged icon suffix without inline explanatory text on the line
- **AND** the situation summary legend SHALL decode the privileged icon meaning

#### Scenario: Missing privileged metadata

- **GIVEN** entitlement privileged metadata is unavailable
- **WHEN** access paths are rendered
- **THEN** lines SHALL render without a privileged badge
- **AND** launch SHALL still succeed

### Requirement: Revocability HTML display with emojis

The sod-remediation operation SHALL render access path annotations in HTML using space-separated UTF-8 emoji icon suffixes on each line in group column form input and in operation `sod-remediation:situation-summary` output. Lines SHALL use shared type tags for access kind. Inline revocability and keep recommendation text labels SHALL NOT appear on lines; meanings SHALL be conveyed by the situation summary legend footer only.

#### Scenario: Group column HTML form input

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** each group side SHALL produce plain, asKept, and asRemoved HTML variants in `groupAContentsHtml`, `groupAContentsHtmlAsKept`, `groupAContentsHtmlAsRemoved`, and B equivalents
- **AND** plain variants SHALL contain type tags and icon suffixes without outcome panel wrappers
- **AND** asKept and asRemoved variants SHALL wrap the same line content in green and red outcome panels respectively
- **AND** the bundled seed SHALL render those keys in conditional DESCRIPTION elements for group A and group B columns

#### Scenario: Group column HTML form input variants

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** formInput SHALL include six group HTML STRING fields covering plain, asKept, and asRemoved for each side
- **AND** seed formConditions SHALL swap visible DESCRIPTION elements when `remediationSide` changes

#### Scenario: Icon suffixes on lines

- **GIVEN** a revocable access path line with keep recommendation `YES`
- **WHEN** HTML is rendered
- **THEN** the line SHALL include space-separated `⭐` and `✅` icon suffixes
- **AND** SHALL NOT include inline text `Revocable` or `Recommended to keep` on the line

#### Scenario: Email summary parity

- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** persisted output `sod-remediation:situation-summary` SHALL include the same access path icon suffixes and side correction hint as the group column HTML line content
- **AND** `situationSummaryHtml` SHALL additionally include the emoji legend footer

---

## REMOVED Requirements

<!-- None -->

---

## RENAMED Requirements

<!-- None -->
