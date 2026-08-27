# connector-operations/sod-remediation Delta

## MODIFIED Requirements

### Requirement: SOD access path resolution

The sod-remediation operation SHALL resolve each conflicting entitlement on a violation side into a display list that includes the entitlement and any access profile or role assigned to the target identity that grants that entitlement. Access path resolution logic SHALL reside under `src/operations/sod-remediation/` and SHALL NOT be part of the generic isc integration layer.

#### Scenario: Entitlement-only side

- **GIVEN** a conflicting entitlement held directly by the target identity
- **WHEN** access paths are resolved for that side
- **THEN** the side display list SHALL include the entitlement
- **AND** the side warning text SHALL use the standard corrective-removal message

#### Scenario: Access profile or role on side

- **GIVEN** a conflicting entitlement granted via an access profile or role assigned to the target identity
- **WHEN** access paths are resolved for that side
- **THEN** the side display list SHALL include the access profile or role in addition to the entitlement
- **AND** the side warning text SHALL state that removing profile- or role-level access may affect other functions of the user

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

#### Scenario: Entitlement-only revocable side unchanged

- **GIVEN** a violation side with conflicting entitlements and no assigned access profile or role granting them
- **WHEN** form input is assembled for launch
- **THEN** that side access search string SHALL include each entitlement id joined with ` OR `
