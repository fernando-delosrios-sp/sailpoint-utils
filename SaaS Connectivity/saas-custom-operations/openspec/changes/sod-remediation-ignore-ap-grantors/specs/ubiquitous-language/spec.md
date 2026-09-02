## ADDED Requirements

### Requirement: Parent access item vocabulary

The project glossary SHALL define **parent access item** as a role or access profile assigned to a target identity that grants a conflicting SoD entitlement and therefore appears as a grantor on an identity access path. For `custom:sod-remediation`, only roles SHALL be treated as parent access items.

#### Scenario: Parent access item term

- **GIVEN** specs describe identity SoD access path grantors
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **parent access item** as a role or access profile on the identity that grants a conflicting entitlement
- **AND** SHALL note that identity SoD path resolution uses roles only, not access profiles

---

## Term entries

### Term: Parent access item
**Context**: connector-operations / sod-remediation
**Definition**: A role or access profile assigned to the target identity that grants a conflicting SoD entitlement and therefore appears as a grantor on the identity access path.
**Aliases**: grantor, elevated path item
**Notes**: `custom:sod-remediation` treats only roles as parent access items. Access profiles are not path grantors on identity SoD. Distinct from access-model **flat access profile line** (catalog composition, not identity assignment).
