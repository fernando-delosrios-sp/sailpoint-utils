# connector-operations/sod-remediation Delta

## ADDED Requirements

### Requirement: Access path revocability annotation

The sod-remediation operation SHALL annotate each resolved access path (entitlement, access profile, role) with workflow-actionable revocability derived from path expansion. Entitlements on a side that also includes an access profile or role SHALL be marked not revocable with reason granted-via-role or granted-via-access-profile. Entitlements on entitlement-only sides SHALL be marked revocable.

#### Scenario: Entitlement-only side

- **GIVEN** a violation side with conflicting entitlements and no assigned access profile or role granting them
- **WHEN** access paths are resolved
- **THEN** each entitlement line SHALL be marked revocable
- **AND** the recommended revoke target SHALL be that entitlement

#### Scenario: Entitlement with role on side

- **GIVEN** a conflicting entitlement granted via an assigned role on the same side
- **WHEN** access paths are resolved
- **THEN** the entitlement line SHALL be marked not revocable with reason granted-via-role
- **AND** the role line SHALL be marked revocable and recommended

#### Scenario: Revoke payload includes revocability metadata

- **WHEN** form input is assembled for launch
- **THEN** each side revoke payload item SHALL include `revocable`, `recommended`, and optional `reason`
- **AND** `recommendedRevoke` SHALL reference the highest-priority revocable item

### Requirement: Revocability HTML display with emojis

The sod-remediation operation SHALL render access path revocability in HTML using UTF-8 emojis alongside text labels in group column form input and in the operation `situationSummary` output.

#### Scenario: Group column HTML form input

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** `groupAContentsHtml` and `groupBContentsHtml` SHALL contain HTML list items with revocability emoji and text labels
- **AND** the bundled seed SHALL render those keys in DESCRIPTION elements for group A and group B columns

#### Scenario: Email summary parity

- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** persisted output `situationSummary` SHALL include the same revocability annotations as the group column HTML
