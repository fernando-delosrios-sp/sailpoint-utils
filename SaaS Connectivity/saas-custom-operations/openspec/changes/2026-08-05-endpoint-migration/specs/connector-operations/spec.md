## Capabilities

### Modified Capabilities

- `connector-operations`: Add `custom:access-request-status`, `custom:govgroup-emails`, `custom:access-request-threshold`, `custom:check-sod-pending`
- `target-client`: Expand `ctx.sdk` with ISC loopback APIs

## Requirements

### Requirement: Access request status operation

The connector SHALL provide `custom:access-request-status` accepting `outputProfile`, `accessRequestId`, and optional `govGroupName`.

#### Scenario: Approval email profile persists routing output

- **GIVEN** a valid access request and `outputProfile` of `approval-email`
- **WHEN** the operation completes successfully
- **THEN** it SHALL persist param1=emailRoute, param2=emailBodyHtml, param3=bccEmails, param4=accessOwnerId

#### Scenario: ETS comment profile persists comment

- **GIVEN** a valid access request and `outputProfile` of `ets-comment`
- **WHEN** the operation completes successfully
- **THEN** it SHALL persist param1=preApprovalComment

### Requirement: Govgroup emails operation

The connector SHALL provide `custom:govgroup-emails` accepting `groupName` and persist param1 as comma-separated emails.

#### Scenario: Threshold operation persists flat params

- **GIVEN** a valid access request, sourceName, and thresholdValue
- **WHEN** `custom:access-request-threshold` completes successfully
- **THEN** it SHALL persist param1=thresholdHit, param2=foundCount, param3=sourceName, param4=thresholdValue, param5=requestedCount, param6=pendingCount, param7=grantedCount

### Requirement: Deferred sod pending operation

The connector SHALL provide `custom:check-sod-pending` returning invoke JSON without persist until a calling workflow exists.
