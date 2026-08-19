## MODIFIED Requirements

### Requirement: Namespaced persist output keys

Each custom operation SHALL persist workflow-readable output on the result source using attribute names prefixed with `{slug}:` where `slug` is the operation command name without the `custom:` prefix. The `OperationSignature` output type, generated operation schema sidecar, operation README, and `ctx.persist` attributes SHALL use the same prefixed keys.

#### Scenario: Output keys use operation slug prefix

- **GIVEN** an operation is registered as `custom:my-op`
- **WHEN** the handler persists output via `ctx.persist`
- **THEN** each output attribute key SHALL begin with `my-op:`
- **AND** SHALL NOT persist unprefixed keys such as `result` or `emails` unless the slug itself contains a colon

#### Scenario: Sod remediation follows namespacing convention

- **GIVEN** `custom:sod-remediation` completes successfully
- **WHEN** operation output is read from the result source
- **THEN** persisted keys SHALL include `sod-remediation:form-url`, `sod-remediation:form-email-header`, `sod-remediation:form-email-body`, and `sod-remediation:form-email-recipients`

#### Scenario: Preventive sod check follows namespacing convention

- **GIVEN** `custom:preventive-sod-check` completes successfully
- **WHEN** operation output is read from the result source
- **THEN** persisted keys SHALL include `preventive-sod-check:has-violation`, `preventive-sod-check:situation-summary`, and `preventive-sod-check:violated-policy-names`

#### Scenario: Access expiration reminders follow namespacing convention

- **GIVEN** `custom:access-expiration-reminders` launches a reminder form and persists a notice account
- **WHEN** operation output is read from the result source
- **THEN** persisted keys SHALL include `access-expiration-reminders:form-url`, `access-expiration-reminders:form-email-header`, `access-expiration-reminders:form-email-body`, and `access-expiration-reminders:form-email-recipients`
- **AND** SHALL include `access-expiration-reminders:identityId`, `access-expiration-reminders:managerId`, and `access-expiration-reminders:accessProfileId`
