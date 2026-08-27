# connector-operations/sod-remediation Delta

## ADDED Requirements

### Requirement: ISC keep recommendation annotation

The sod-remediation operation SHALL fetch ISC keep recommendations for each resolved access path item on the violation target identity at launch using the Recommendations API. Items whose recommendation is `YES` SHALL be annotated for display as recommended to keep. Items whose recommendation is `MAYBE`, `NO`, or `NOT_FOUND` SHALL NOT receive a keep star.

#### Scenario: Batch keep recommendations at launch

- **GIVEN** resolved access paths for Group A and Group B
- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** the handler SHALL request keep recommendations for all unique access items across both sides in a single batch call
- **AND** SHALL map each response back to the corresponding access path line by item id and type

#### Scenario: YES shows keep star

- **GIVEN** the Recommendations API returns `YES` for a role on Group B
- **WHEN** form input and situation summary HTML are rendered
- **THEN** that role line SHALL include a keep star with label Recommended to keep
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

### Requirement: Side correction recommendation

When keep recommendations exist on exactly one violation group, the sod-remediation operation SHALL recommend correcting the opposite group. When both groups have at least one `YES` keep recommendation or neither group has any `YES`, the operation SHALL emit no side correction recommendation.

#### Scenario: Recommend correct Group A

- **GIVEN** Group A has no items with keep recommendation `YES`
- **AND** Group B has at least one item with keep recommendation `YES`
- **WHEN** form input and situation summary are assembled
- **THEN** the operation SHALL recommend correcting Group A
- **AND** SHALL expose `recommendedSideToCorrect` value `groupA` in launch context suitable for workflow consumption

#### Scenario: Recommend correct Group B

- **GIVEN** Group A has at least one item with keep recommendation `YES`
- **AND** Group B has no items with keep recommendation `YES`
- **WHEN** form input and situation summary are assembled
- **THEN** the operation SHALL recommend correcting Group B

#### Scenario: No side recommendation when symmetric

- **GIVEN** both Group A and Group B have at least one `YES` keep recommendation
- **WHEN** HTML is rendered
- **THEN** the operation SHALL NOT display a side correction recommendation

#### Scenario: Side hint in form and email

- **GIVEN** a side correction recommendation is computed
- **WHEN** form input and operation output are produced
- **THEN** the side hint SHALL appear in group column DESCRIPTION HTML and in `situationSummary`

### Requirement: Privileged access indicator

The sod-remediation operation SHALL annotate entitlement access path lines with a privileged indicator when entitlement metadata marks the entitlement as privileged.

#### Scenario: Privileged entitlement badge

- **GIVEN** entitlement metadata indicates an entitlement is privileged
- **WHEN** access path HTML is rendered
- **THEN** that entitlement line SHALL include a privileged badge using UTF-8 emoji

#### Scenario: Missing privileged metadata

- **GIVEN** entitlement privileged metadata is unavailable
- **WHEN** access paths are rendered
- **THEN** lines SHALL render without a privileged badge
- **AND** launch SHALL still succeed

## MODIFIED Requirements

### Requirement: Access path revocability annotation

The sod-remediation operation SHALL annotate each resolved access path with workflow-actionable revocability derived from path expansion. Entitlements on a side that also includes an access profile or role granting that entitlement SHALL be marked not directly revocable and SHALL include a named grantor reference. Entitlements on entitlement-only sides SHALL be marked revocable. Connector revoke recommendation SHALL NOT be shown in owner-facing HTML.

#### Scenario: Entitlement-only side

- **GIVEN** a violation side with conflicting entitlements and no assigned access profile or role granting them
- **WHEN** access paths are resolved
- **THEN** each entitlement line SHALL be marked revocable
- **AND** SHALL NOT display a connector revoke recommendation star

#### Scenario: Entitlement with named role grantor

- **GIVEN** a conflicting entitlement granted via role "B2B Buyer" on the same side
- **WHEN** access paths are resolved and HTML is rendered
- **THEN** the entitlement line SHALL be marked not directly revocable with reason granted-via-role
- **AND** the reason text SHALL name the grantor as granted via B2B Buyer role
- **AND** the role line SHALL be marked revocable without a connector revoke star in HTML

#### Scenario: Entitlement with role on side

- **GIVEN** a conflicting entitlement granted via an assigned role on the same side
- **WHEN** access paths are resolved
- **THEN** the entitlement line SHALL be marked not directly revocable with reason granted-via-role
- **AND** the role line SHALL be marked revocable without owner-visible connector revoke star

#### Scenario: Revoke payload includes revocability metadata

- **WHEN** form input is assembled for launch
- **THEN** each side revoke payload item SHALL include `revocable`, optional `reason`, optional `grantedVia`, and optional `keepRecommendation`
- **AND** `recommendedRevoke` SHALL reference the highest-priority revocable item for workflow use without owner-visible star

#### Scenario: Revoke payload includes keep metadata

- **WHEN** form input is assembled for launch
- **THEN** each side revoke payload item SHALL include `revocable`, optional `reason`, optional `grantedVia`, and optional `keepRecommendation`
- **AND** `recommendedRevoke` MAY remain for workflow use without owner-visible star

### Requirement: Revocability HTML display with emojis

The sod-remediation operation SHALL render access path annotations in HTML using UTF-8 emojis alongside text labels in group column form input and in operation `situationSummary` output. Keep recommendation stars SHALL use distinct copy from revocability labels.

#### Scenario: Group column HTML form input

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** `groupAContentsHtml` and `groupBContentsHtml` SHALL contain HTML list items with revocability emoji and text labels
- **AND** keep recommendation stars SHALL appear only for `YES` responses with label Recommended to keep
- **AND** the bundled seed SHALL render those keys in DESCRIPTION elements for group A and group B columns

#### Scenario: Email summary parity

- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** persisted output `situationSummary` SHALL include the same access path annotations and side correction hint as the group column HTML
