# connector-operations/sod-remediation Delta

## MODIFIED Requirements

### Requirement: SOD access path resolution

The sod-remediation operation SHALL resolve each conflicting entitlement on a violation side into a display list that includes the entitlement and any **role** assigned to the target identity that grants that entitlement. Access profiles SHALL NOT appear as parent access items on the path. Access path resolution logic SHALL reside under `src/operations/sod-remediation/` and SHALL NOT be part of the generic isc integration layer.

#### Scenario: Entitlement-only side

- **GIVEN** a conflicting entitlement held by the target identity
- **AND** no assigned role grants that entitlement
- **WHEN** access paths are resolved for that side
- **THEN** the side display list SHALL include the entitlement
- **AND** SHALL NOT include an access profile line
- **AND** the side warning text SHALL use the standard corrective-removal message

#### Scenario: Assigned access profile is not a parent access item

- **GIVEN** a conflicting entitlement whose definition is also contained in an access profile assigned to the target identity
- **AND** no assigned role grants that entitlement
- **WHEN** access paths are resolved for that side
- **THEN** the side display list SHALL include the entitlement
- **AND** SHALL NOT include the access profile
- **AND** that side access search string SHALL include the entitlement id
- **AND** SHALL NOT include the access profile id

#### Scenario: Role on side

- **GIVEN** a conflicting entitlement granted via a role assigned to the target identity
- **WHEN** access paths are resolved for that side
- **THEN** the side display list SHALL include the role in addition to the entitlement
- **AND** the side warning text SHALL state that removing role-level access may affect other functions of the user

#### Scenario: Access profile or role on side

- **GIVEN** a conflicting entitlement granted via an access profile or role assigned to the target identity
- **WHEN** access paths are resolved for that side
- **THEN** when the grantor is a role, the side display list SHALL include the role in addition to the entitlement
- **AND** the side display list SHALL NOT include an access profile
- **AND** when a role is on the path, the side warning text SHALL state that removing role-level access may affect other functions of the user

#### Scenario: Hidden access search string per side

- **WHEN** form input is assembled for launch
- **THEN** each side SHALL produce an ISC access-item search filter joining **revocable** resolved path item ids with ` OR ` in the form `id:{uuid}`
- **AND** SHALL NOT include ids for access path items marked not revocable

#### Scenario: Single-item side search string

- **GIVEN** a violation side with one revocable resolved access path item
- **WHEN** form input is assembled for launch
- **THEN** that side access search string SHALL be `id:{itemId}` without an ` OR ` suffix

#### Scenario: Mixed revocable and non-revocable items on side

- **GIVEN** a conflicting entitlement granted via an assigned role on the same side
- **AND** the entitlement line is marked not revocable
- **AND** the role line is marked revocable
- **WHEN** form input is assembled for launch
- **THEN** that side access search string SHALL include only the role id
- **AND** SHALL NOT include the entitlement id

#### Scenario: Role plus standalone entitlement on side

- **GIVEN** one conflicting entitlement granted via an assigned role
- **AND** another conflicting entitlement on the same side with no assigned role grantor
- **WHEN** form input is assembled for launch
- **THEN** that side access search string SHALL include the role id and the standalone entitlement id
- **AND** SHALL NOT include the role-granted entitlement id

#### Scenario: Entitlement-only revocable side unchanged

- **GIVEN** a violation side with conflicting entitlements and no assigned role granting them
- **WHEN** form input is assembled for launch
- **THEN** that side access search string SHALL include each entitlement id joined with ` OR `

### Requirement: Access path revocability annotation

The sod-remediation operation SHALL annotate each resolved access path with workflow-actionable revocability derived from path expansion. Entitlements on a side that also includes a **role** granting that entitlement SHALL be marked not directly revocable and SHALL include a named grantor reference. Entitlements without a role grantor SHALL be marked revocable even when an assigned access profile also contains them. Connector revoke recommendation SHALL NOT be shown in owner-facing HTML.

#### Scenario: Entitlement-only side

- **GIVEN** a violation side with conflicting entitlements and no assigned role granting them
- **WHEN** access paths are resolved
- **THEN** each entitlement line SHALL be marked revocable
- **AND** SHALL NOT display a connector revoke recommendation star

#### Scenario: Entitlement with assigned access profile only

- **GIVEN** a conflicting entitlement contained in an access profile assigned to the target identity
- **AND** no assigned role grants that entitlement
- **WHEN** access paths are resolved
- **THEN** the entitlement line SHALL be marked revocable with reason direct-assignment
- **AND** SHALL NOT use reason granted-via-access-profile
- **AND** SHALL NOT include a grantedVia access profile reference

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

#### Scenario: Role preferred over access profile when both grant

- **GIVEN** a conflicting entitlement granted via an assigned role
- **AND** an assigned access profile also contains that entitlement
- **WHEN** access paths are resolved
- **THEN** the entitlement line SHALL be marked not directly revocable with reason granted-via-role
- **AND** the display list SHALL include the role
- **AND** SHALL NOT include the access profile

#### Scenario: Revoke payload includes revocability metadata

- **WHEN** form input is assembled for launch
- **THEN** each side revoke payload item SHALL include `revocable`, optional `reason`, optional `grantedVia`, and optional `keepRecommendation`
- **AND** `recommendedRevoke` SHALL reference the highest-priority revocable item for workflow use without owner-visible star

#### Scenario: Revoke payload includes keep metadata

- **WHEN** form input is assembled for launch
- **THEN** each side revoke payload item SHALL include `revocable`, optional `reason`, optional `grantedVia`, and optional `keepRecommendation`
- **AND** `recommendedRevoke` MAY remain for workflow use without owner-visible star
