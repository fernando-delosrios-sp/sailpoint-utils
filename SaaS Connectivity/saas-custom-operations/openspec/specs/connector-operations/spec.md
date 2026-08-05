## Purpose

Custom command handlers registered in the connector for ISC custom operations, using the custom-operation framework wrapper.

## Requirements

### Requirement: Custom command registration

The connector SHALL register custom command handlers and SHALL NOT register any std command handlers.

#### Scenario: Custom command invoked

- **GIVEN** a custom command is declared in connector-spec.json and registered in the connector
- **WHEN** ISC invokes that custom command
- **THEN** the connector SHALL execute the registered handler via withCustomOperation

#### Scenario: No std handlers registered

- **GIVEN** the connector is initialized
- **WHEN** the connector command registry is inspected
- **THEN** no std:account:list, std:account:read, or std:test-connection handlers SHALL be registered

### Requirement: Operations registry pattern

The connector SHALL provide an operations module where authors register custom commands, with an example operation included as a template.

#### Scenario: Example operation available

- **GIVEN** the foundation template is built
- **WHEN** a developer inspects src/operations/
- **THEN** an example custom operation SHALL be present demonstrating ctx.sdk, ctx.log, and ctx.persist usage

### Requirement: Access request status operation

The connector SHALL provide `custom:access-request-status` accepting `outputProfile`, `accessRequestId`, and optional `govGroupName`.

#### Scenario: Approval email profile persists routing output

- **GIVEN** a valid access request and `outputProfile` of `approval-email`
- **WHEN** the operation completes successfully
- **THEN** it SHALL persist emailRoute, emailBodyHtml, bccEmails, and accessOwnerId as named output attributes

#### Scenario: ETS comment profile persists comment

- **GIVEN** a valid access request and `outputProfile` of `ets-comment`
- **WHEN** the operation completes successfully
- **THEN** it SHALL persist preApprovalComment as a named output attribute

### Requirement: Govgroup emails operation

The connector SHALL provide `custom:govgroup-emails` accepting `groupName` and persist member emails as a multi-valued string array output attribute.

#### Scenario: Govgroup emails persisted

- **GIVEN** a valid governance group name
- **WHEN** `custom:govgroup-emails` completes successfully
- **THEN** it SHALL persist the resolved emails on the dummy source account

### Requirement: Access request threshold operation

The connector SHALL provide `custom:access-request-threshold` accepting access request context and threshold inputs.

#### Scenario: Threshold operation persists analytics output

- **GIVEN** a valid access request, sourceName, and thresholdValue
- **WHEN** `custom:access-request-threshold` completes successfully
- **THEN** it SHALL persist thresholdHit, foundCount, sourceName, thresholdValue, requestedCount, pendingCount, and grantedCount as named output attributes

### Requirement: Deferred sod pending operation

The connector SHALL provide `custom:check-sod-pending` returning invoke JSON without persist until a calling workflow exists.

#### Scenario: Sod pending returns invoke response only

- **GIVEN** a valid sod check input
- **WHEN** `custom:check-sod-pending` completes successfully
- **THEN** it SHALL send structured output via ctx.res.send and SHALL NOT call ctx.persist

