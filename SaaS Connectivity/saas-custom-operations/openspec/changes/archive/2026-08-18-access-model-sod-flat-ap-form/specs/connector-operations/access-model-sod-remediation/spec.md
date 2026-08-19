## MODIFIED Requirements

### Requirement: Access model SOD group column HTML styling

The access-model-sod-remediation operation SHALL render group A and group B entitlement columns using shared sod-form-html builders. Columns SHALL use type tags and selection-gated outcome panels. The operation SHALL NOT render revocability emojis or an emoji legend.

#### Scenario: Six group HTML formInput fields

- **WHEN** `custom:access-model-sod-remediation` assembles form input for a violation
- **THEN** formInput SHALL include `groupAContentsHtml`, `groupAContentsHtmlAsKept`, `groupAContentsHtmlAsRemoved`, `groupBContentsHtml`, `groupBContentsHtmlAsKept`, and `groupBContentsHtmlAsRemoved`
- **AND** plain variants SHALL NOT include outcome panel wrappers

#### Scenario: Flat access profile lines with offending entitlement mention

- **GIVEN** a violating role with entitlements granted via nested access profiles on a policy side
- **WHEN** group column HTML is rendered
- **THEN** each nested access profile on that side SHALL appear as a single flat list row
- **AND** the row SHALL include an offending entitlement mention naming the side-matching entitlement display names
- **AND** nested entitlement bullets under the access profile SHALL NOT be used
- **AND** direct role entitlements on that side SHALL remain single flat entitlement rows with type tags

#### Scenario: Outcome panels apply to whole access profile rows

- **GIVEN** group column HTML includes a flat access profile line on Group B
- **WHEN** the recipient selects `remediationSide` value `groupA`
- **THEN** the entire Group B access profile row SHALL appear in the green kept outcome panel variant
- **AND** SHALL NOT apply outcome styling only to a nested entitlement sub-row

#### Scenario: Plain variants before selection

- **GIVEN** the bundled access-model-sod-remediation seed with formConditions for group columns
- **WHEN** the recipient has not selected `remediationSide`
- **THEN** plain `groupAContentsHtml` and `groupBContentsHtml` SHALL be visible
- **AND** outcome panel variants SHALL be hidden

#### Scenario: Outcome panels after side selection

- **GIVEN** the recipient selects `remediationSide` value `groupA`
- **WHEN** formConditions evaluate
- **THEN** Group A SHALL display `groupAContentsHtmlAsRemoved` with red outcome panel styling
- **AND** Group B SHALL display `groupBContentsHtmlAsKept` with green outcome panel styling

#### Scenario: No side-identity colored panels

- **WHEN** group column HTML is rendered for access-model-sod-remediation
- **THEN** the output SHALL NOT use always-on blue or purple side-identity panel backgrounds
- **AND** colored backgrounds SHALL appear only in asKept or asRemoved variants after selection

#### Scenario: No emojis on access catalog form

- **WHEN** access-model-sod-remediation group HTML is rendered
- **THEN** lines SHALL NOT include revocability, keep, or privileged emoji suffixes
- **AND** SHALL NOT include an emoji legend footer

#### Scenario: Side-by-side column layout preserved

- **GIVEN** the bundled access-model-sod-remediation seed
- **WHEN** the Correct section is inspected
- **THEN** Group A and Group B contents SHALL remain in a two-column COLUMN_SET layout

## REMOVED Requirements

### Requirement: Access model SOD group column HTML styling

#### Scenario: Nested access profile tree preserved

**Reason**: Nested AP trees implied entitlement-level trim inside shared access profiles; remediation will detach whole access profiles from roles.

**Migration**: No workflow changes; new form instances receive flat AP lines at launch. Rescan or recreate forms to refresh in-flight ASSIGNED instances.
