## ADDED Requirements

### Requirement: Access model context panel HTML

The access-model-sod-remediation operation SHALL assemble launch-time `situationSummaryHtml` for in-form DESCRIPTION rendering. The summary SHALL use the same “What we found” / “What we need from you” structure as sod-remediation context panels. When UI origin is available, the summary SHALL link the access item and policy display names to ISC admin UI routes. The bundled seed SHALL interpolate `situationSummaryHtml` in a single context-panel DESCRIPTION and SHALL NOT rely on static-only access item metadata for situation explanation.

#### Scenario: Form input includes situationSummaryHtml

- **WHEN** `custom:access-model-sod-remediation` creates a form instance
- **THEN** `formInput` SHALL include `situationSummaryHtml` with HTML suitable for DESCRIPTION interpolation

#### Scenario: Linked access item and policy

- **GIVEN** UI origin is available, role id `role-r`, and policy id `policy-p`
- **WHEN** `situationSummaryHtml` is assembled
- **THEN** the access item display name SHALL link to the role admin UI route
- **AND** the policy display name SHALL link to the SoD policy admin UI route

#### Scenario: Access profile item links correctly

- **GIVEN** UI origin is available and violating access item type is `ACCESS_PROFILE`
- **WHEN** `situationSummaryHtml` is assembled
- **THEN** the access item display name SHALL link to the access profile admin UI route

#### Scenario: Call to action for policy owner

- **WHEN** `situationSummaryHtml` is assembled
- **THEN** the “What we need from you” block SHALL instruct the recipient to select which side’s entitlements to remove from the access item definition

#### Scenario: Offline context panel omits links

- **GIVEN** invoke runs without `apiUrl`
- **WHEN** `situationSummaryHtml` is assembled
- **THEN** names SHALL render as plain escaped text without admin links

#### Scenario: Seed single context DESCRIPTION

- **GIVEN** the bundled access-model-sod-remediation seed
- **WHEN** the context section is inspected
- **THEN** exactly one DESCRIPTION element SHALL interpolate `{{$.form.input.situationSummaryHtml}}`
- **AND** the seed SHALL NOT define static-only element id `ctx-item` for situation content

---

## MODIFIED Requirements

### Requirement: Access model SOD remediation form launch

The access-model-sod-remediation operation SHALL ensure a shared form definition by `formName`, populate launch-time `formInput` with access item and policy context plus `situationSummaryHtml`, group entitlement id lists and HTML summaries, and create standalone form instances for the policy owner. The form SHALL expose Correct-only side selection without an action selector or Mitigate path. Launch-time `formInput` SHALL include `parentRequestId` set to the scan invoke `requestId` (declared in the form definition, no UI element).

#### Scenario: Form recipient is policy owner

- **GIVEN** policy `policy-p` has `ownerRef` identity `owner-z`
- **WHEN** a form is created for a violation of `policy-p`
- **THEN** the form instance recipient SHALL be identity `owner-z`

#### Scenario: Form input carries access item context

- **GIVEN** role `role-r` named `Finance Role` violates policy `policy-p` named `AP/AR Separation`
- **WHEN** the form instance is created
- **THEN** `formInput` SHALL include `accessItemId` `role-r`, `accessItemType` `ROLE`, `accessItemName` `Finance Role`, `policyId` `policy-p`, and `policyName` `AP/AR Separation`
- **AND** the role SHALL NOT appear as a line item in group A or group B HTML columns

#### Scenario: Form input carries parent request id

- **GIVEN** invoke `requestId` `scan-parent-1` creates a remediation form for a violation
- **WHEN** the form instance is created
- **THEN** `formInput.parentRequestId` SHALL be `scan-parent-1`
- **AND** `parentRequestId` SHALL be declared in the form definition `formInput` without a corresponding form element

#### Scenario: Group ids are entitlement ids only

- **GIVEN** a violating access item with group intersections `ent-a` and `ent-c`
- **WHEN** the form instance is created
- **THEN** `formInput.groupAIds` SHALL be `['ent-a']`
- **AND** `formInput.groupBIds` SHALL be `['ent-c']`
- **AND** nested access profile ids SHALL NOT appear in group id lists even when HTML groups entitlements under an AP label

#### Scenario: Form submit returns remediation side

- **GIVEN** a submitted form with `formData.remediationSide` set to `groupA`
- **WHEN** a downstream workflow applies the decision
- **THEN** it SHALL invoke `custom:access-model-sod-remediation-apply` with `formInstanceId` only
- **AND** the correct operation SHALL interpret `groupAIds` from `formInput` to detach nested access profiles or remove direct role entitlements per side entitlement ids
- **AND** the form SHALL NOT include `formData.action` or Mitigate fields

#### Scenario: Idempotent form creation

- **GIVEN** invoke `requestId` `scan-parent-1` detects violation for access item `role-r` and policy `policy-p`
- **AND** a result-source account already exists with native identity `scan-parent-1:role-r:policy-p`
- **WHEN** the scan detects the same violation again for `scan-parent-1`
- **THEN** the handler SHALL NOT create a duplicate form instance
- **AND** SHALL increment `access-model-sod-remediation:forms-skipped` in the final `ctx.res.send` summary

#### Scenario: No sod-remediation violation fields

- **GIVEN** a successful form launch
- **WHEN** the handler completes
- **THEN** operation output SHALL NOT require `violationId`, `sod-remediation:*` fields, or compensating control options

---

## MODIFIED Requirements

### Requirement: Access model SOD group column HTML styling

The access-model-sod-remediation operation SHALL render group A and group B entitlement columns using shared sod-form-html builders. Columns SHALL use type tags and selection-gated outcome panels. When UI origin is available, line display names SHALL link to ISC admin UI routes. The operation SHALL NOT render revocability emojis or an emoji legend in group column HTML.

#### Scenario: Six group HTML formInput fields

- **WHEN** `custom:access-model-sod-remediation` assembles form input for a violation
- **THEN** formInput SHALL include `groupColumnsHtmlPlain`, `groupColumnsHtmlWhenGroupARemoved`, and `groupColumnsHtmlWhenGroupBRemoved`
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
- **THEN** plain group column HTML SHALL be visible
- **AND** outcome panel variants SHALL be hidden

#### Scenario: Outcome panels after side selection

- **GIVEN** the recipient selects `remediationSide` value `groupA`
- **WHEN** formConditions evaluate
- **THEN** Group A SHALL display removed outcome panel styling
- **AND** Group B SHALL display kept outcome panel styling

#### Scenario: No side-identity colored panels

- **WHEN** group column HTML is rendered for access-model-sod-remediation
- **THEN** the output SHALL NOT use always-on blue or purple side-identity panel backgrounds
- **AND** colored backgrounds SHALL appear only in asKept or asRemoved variants after selection

#### Scenario: No emojis on access catalog form

- **WHEN** access-model-sod-remediation group column HTML is rendered
- **THEN** lines SHALL NOT include revocability, keep, or privileged emoji suffixes
- **AND** group column HTML SHALL NOT include an emoji legend footer

#### Scenario: Linked column line names when online

- **GIVEN** UI origin is available
- **WHEN** group column HTML is rendered
- **THEN** entitlement and access profile display names SHALL be wrapped in the corresponding ISC admin UI links

#### Scenario: Side-by-side column layout preserved

- **GIVEN** the bundled access-model-sod-remediation seed
- **WHEN** the Correct section is inspected
- **THEN** Group A and Group B contents SHALL remain in a side-by-side two-column layout
