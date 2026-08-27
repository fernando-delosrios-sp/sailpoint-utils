## ADDED Requirements

### Requirement: Role catalog patch helpers

The isc roles module SHALL provide helpers to mutate role composition and description via `getRoleV1` and `patchRoleV1` without encoding access-model-sod-remediation-apply orchestration.

#### Scenario: Detach access profiles from role

- **GIVEN** role `role-r` includes access profiles `{ap-a, ap-b}` and caller requests detach `{ap-a}`
- **WHEN** `detachRoleAccessProfiles` is invoked
- **THEN** the helper SHALL PATCH role `role-r` so `accessProfiles` no longer includes `ap-a`
- **AND** SHALL preserve other role fields not targeted by the operation

#### Scenario: Remove direct role entitlements

- **GIVEN** role `role-r` direct entitlements `{ent-1, ent-2}` and caller requests removal `{ent-1}`
- **WHEN** `removeRoleEntitlements` is invoked
- **THEN** the helper SHALL PATCH role `role-r` so direct entitlements no longer include `ent-1`

#### Scenario: Append role description

- **GIVEN** role `role-r` with existing description text
- **WHEN** `appendRoleDescription` is invoked with an audit line
- **THEN** the helper SHALL PATCH role `role-r` description by appending the audit line
