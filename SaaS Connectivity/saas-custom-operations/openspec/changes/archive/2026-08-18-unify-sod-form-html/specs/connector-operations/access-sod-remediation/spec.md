## ADDED Requirements

### Requirement: Access SOD group column HTML styling

The access-sod-remediation operation SHALL render group A and group B entitlement columns using shared sod-form-html builders. Columns SHALL use type tags and selection-gated outcome panels. The operation SHALL NOT render revocability emojis or an emoji legend.

#### Scenario: Six group HTML formInput fields

- **WHEN** `custom:access-sod-remediation` assembles form input for a violation
- **THEN** formInput SHALL include `groupAContentsHtml`, `groupAContentsHtmlAsKept`, `groupAContentsHtmlAsRemoved`, `groupBContentsHtml`, `groupBContentsHtmlAsKept`, and `groupBContentsHtmlAsRemoved`
- **AND** plain variants SHALL NOT include outcome panel wrappers

#### Scenario: Nested access profile tree preserved

- **GIVEN** a violating role with entitlements grouped under nested access profile labels
- **WHEN** group column HTML is rendered
- **THEN** entitlements SHALL appear nested under their access profile name
- **AND** each line SHALL include a type tag for entitlement or access profile as appropriate

#### Scenario: Plain variants before selection

- **GIVEN** the bundled access-sod-remediation seed with formConditions for group columns
- **WHEN** the recipient has not selected `remediationSide`
- **THEN** plain `groupAContentsHtml` and `groupBContentsHtml` SHALL be visible
- **AND** outcome panel variants SHALL be hidden

#### Scenario: Outcome panels after side selection

- **GIVEN** the recipient selects `remediationSide` value `groupA`
- **WHEN** formConditions evaluate
- **THEN** Group A SHALL display `groupAContentsHtmlAsRemoved` with red outcome panel styling
- **AND** Group B SHALL display `groupBContentsHtmlAsKept` with green outcome panel styling

#### Scenario: No side-identity colored panels

- **WHEN** group column HTML is rendered for access-sod-remediation
- **THEN** the output SHALL NOT use always-on blue or purple side-identity panel backgrounds
- **AND** colored backgrounds SHALL appear only in asKept or asRemoved variants after selection

#### Scenario: No emojis on access catalog form

- **WHEN** access-sod-remediation group HTML is rendered
- **THEN** lines SHALL NOT include revocability, keep, or privileged emoji suffixes
- **AND** SHALL NOT include an emoji legend footer

#### Scenario: Side-by-side column layout preserved

- **GIVEN** the bundled access-sod-remediation seed
- **WHEN** the Correct section is inspected
- **THEN** Group A and Group B contents SHALL remain in a two-column COLUMN_SET layout

---

## MODIFIED Requirements

<!-- access-sod-remediation canonical spec not yet archived; styling requirements added above as ADDED. -->

---

## REMOVED Requirements

<!-- None -->

---

## RENAMED Requirements

<!-- None -->
