## ADDED Requirements

### Requirement: Access profile owner identity extraction

The isc access-profiles module SHALL extract the primary access profile owner identity id from an access profile `owner` reference for callers that need an IDENTITY form recipient. Extraction logic SHALL reside under `src/isc/access-profiles/` and SHALL NOT encode access-model-sod-remediation orchestration.

#### Scenario: Access profile owner identity extraction

- **GIVEN** access profile `ap-v` has `owner.type` `IDENTITY` (or omitted type) and `owner.id` `item-owner-2`
- **WHEN** `resolveAccessProfileOwnerId` is invoked with that owner reference (or after fetching the access profile)
- **THEN** the function SHALL return `item-owner-2`

#### Scenario: Missing access profile owner fails

- **GIVEN** access profile `ap-v` has no `owner.id`
- **WHEN** `resolveAccessProfileOwnerId` is invoked
- **THEN** the function SHALL throw ConnectorError indicating the access profile has no owner identity

#### Scenario: Non-IDENTITY access profile owner fails

- **GIVEN** access profile `ap-v` has `owner.type` other than `IDENTITY` with an id present
- **WHEN** `resolveAccessProfileOwnerId` is invoked
- **THEN** the function SHALL throw ConnectorError indicating IDENTITY is required
