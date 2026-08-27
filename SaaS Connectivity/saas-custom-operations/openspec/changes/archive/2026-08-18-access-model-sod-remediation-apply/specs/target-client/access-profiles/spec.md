## ADDED Requirements

### Requirement: Access profile catalog patch helpers

The isc access-profiles module SHALL provide helpers to mutate access profile entitlements and description via `getAccessProfileV1` and `patchAccessProfileV1` without encoding access-model-sod-remediation-apply orchestration.

#### Scenario: Remove access profile entitlements

- **GIVEN** access profile `ap-v` entitlements `{ent-1, ent-2}` and caller requests removal `{ent-1}`
- **WHEN** `removeAccessProfileEntitlements` is invoked
- **THEN** the helper SHALL PATCH access profile `ap-v` so entitlements no longer include `ent-1`

#### Scenario: Append access profile description

- **GIVEN** access profile `ap-v` with existing description text
- **WHEN** `appendAccessProfileDescription` is invoked with an audit line
- **THEN** the helper SHALL PATCH access profile `ap-v` description by appending the audit line
