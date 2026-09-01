## ADDED Requirements

### Requirement: Access expiration reminder terms

The glossary SHALL define **access expiration reminder**, **expiration notice account**, **expiration days**, **response account id**, **new expiration date**, and **reminder scan summary** for `custom:access-expiration-reminders`.

#### Scenario: Access expiration reminder term

- **GIVEN** specs or code refer to manager notices for expiring ACCESS_PROFILE assignments
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **access expiration reminder** as a notice that an identity’s ACCESS_PROFILE assignment will expire on a specific `removeDate`, addressed to that identity’s manager via a standalone ISC form
- **AND** the preferred command SHALL be `custom:access-expiration-reminders`

#### Scenario: Expiration notice account term

- **GIVEN** specs describe per-notice result-source accounts for access expiration reminders
- **WHEN** normative text names that account
- **THEN** it SHALL use **expiration notice account** for native identity `` `${requestId}:${identityId}:${accessProfileId}` ``

#### Scenario: Expiration days term

- **GIVEN** specs name the matching threshold input
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **expiration days** as optional invoke input `expirationDays` (default `1`) meaning the exact UTC calendar-day difference between the run date and assignment `removeDate`
- **AND** SHALL NOT use rolling hour-based day counts as the preferred matching rule

#### Scenario: Response account id term

- **GIVEN** form inputs for access expiration reminders are documented
- **WHEN** naming the correlation form field
- **THEN** it SHALL use **response account id** spelled `responseAccountId`
- **AND** its value SHALL equal the expiration notice account native identity

#### Scenario: New expiration date term

- **GIVEN** the manager form collects a replacement end date
- **WHEN** naming the form element key
- **THEN** it SHALL use **new expiration date** spelled `newExpirationDate`

#### Scenario: Reminder scan summary term

- **GIVEN** specs refer to rollup counts from `custom:access-expiration-reminders`
- **WHEN** normative text names the delivery mechanism
- **THEN** it SHALL use **reminder scan summary** for the invoke response envelope `summary` via `ctx.respond`
- **AND** SHALL NOT describe those counters as a parent result-source account on `requestId`

---

## MODIFIED Requirements

### Requirement: Form email recipients term

The glossary SHALL define **form email recipients** as the multi-value persist output listing email addresses for ISC workflow Send Email `recipientEmailList` after SOD form launch operations and access expiration reminder form launch.

#### Scenario: Preferred persist key spelling

- **GIVEN** specs or code name the recipient email persist output on `custom:sod-remediation`, `custom:access-model-sod-remediation`, or `custom:access-expiration-reminders`
- **WHEN** the ubiquitous language spec is read
- **THEN** the preferred attribute suffix SHALL be `form-email-recipients` (plural)
- **AND** the deprecated singular `form-email-recipient` SHALL NOT appear in normative text without a migration note

#### Scenario: Type is string array

- **GIVEN** documentation describes the form email recipients persist field
- **WHEN** the type is stated
- **THEN** it SHALL be described as `string[]` suitable for multi-value STRING account attributes with `isMulti: true`

#### Scenario: Access expiration reminders use form email recipients

- **GIVEN** documentation lists operations that persist form email recipients
- **WHEN** `custom:access-expiration-reminders` is included
- **THEN** it SHALL use prefix `access-expiration-reminders:form-email-recipients`
- **AND** the sole recipient for a launched notice SHALL be the identity manager’s email when present
