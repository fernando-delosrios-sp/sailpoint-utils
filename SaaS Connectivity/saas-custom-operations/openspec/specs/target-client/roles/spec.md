# target-client/roles Specification

## Purpose

Generic RolesApi wrappers under `src/isc/roles/`. Callers supply role ids; this module SHALL NOT encode operation-specific access path assembly.

## Requirements

### Requirement: Role entitlement listing

The isc roles module SHALL return entitlement ids granted by a role via `getRoleEntitlementsV1`.

#### Scenario: Entitlement ids returned

- **GIVEN** a configured `RolesApi` and role id `{roleId}`
- **WHEN** `listRoleEntitlementIds` is invoked
- **THEN** the function SHALL call `getRoleEntitlementsV1`
- **AND** SHALL return entitlement ids from the response

### Requirement: Enabled roles listing with search filter

The isc roles module SHALL provide paginated listing of enabled roles with an optional ISC search filter string. Listing logic SHALL reside under `src/isc/roles/` and SHALL NOT encode access-model-sod-remediation operation orchestration.

#### Scenario: List all enabled roles

- **GIVEN** a configured RolesApi client and scope `"*"`
- **WHEN** `listEnabledRoles` is invoked
- **THEN** the function SHALL paginate through role list results
- **AND** SHALL return only enabled roles

#### Scenario: List roles with name filter

- **GIVEN** scope filter `name sw "Finance-"`
- **WHEN** `listEnabledRoles` is invoked
- **THEN** the function SHALL apply the filter in addition to the enabled constraint

#### Scenario: Offline stub role list

- **GIVEN** offline/testMode invocation
- **WHEN** `listEnabledRolesOffline` is invoked
- **THEN** the function SHALL return deterministic canned roles suitable for access-model-sod-remediation tests

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

### Requirement: Role owner identity extraction

The isc roles module SHALL extract the primary role owner identity id from a role `owner` reference for callers that need an IDENTITY form recipient. Extraction logic SHALL reside under `src/isc/roles/` and SHALL NOT encode access-model-sod-remediation orchestration.

#### Scenario: Role owner identity extraction

- **GIVEN** role `role-r` has `owner.type` `IDENTITY` (or omitted type) and `owner.id` `item-owner-1`
- **WHEN** `resolveRoleOwnerId` is invoked with that role owner reference (or after fetching the role)
- **THEN** the function SHALL return `item-owner-1`

#### Scenario: Missing role owner fails

- **GIVEN** role `role-r` has no `owner.id`
- **WHEN** `resolveRoleOwnerId` is invoked
- **THEN** the function SHALL throw ConnectorError indicating the role has no owner identity

#### Scenario: Non-IDENTITY role owner fails

- **GIVEN** role `role-r` has `owner.type` other than `IDENTITY` with an id present
- **WHEN** `resolveRoleOwnerId` is invoked
- **THEN** the function SHALL throw ConnectorError indicating IDENTITY is required
