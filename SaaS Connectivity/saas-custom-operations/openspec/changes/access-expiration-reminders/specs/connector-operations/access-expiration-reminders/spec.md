## ADDED Requirements

### Requirement: Access expiration reminders operation

The connector SHALL register a custom command `custom:access-expiration-reminders` that discovers identities with ACCESS_PROFILE assignments whose `removeDate` is exactly `expirationDays` UTC calendar days from the run date, creates a standalone manager reminder form per matching assignment (subject to caps and skips), persists one expiration notice account per launched form, and returns a reminder scan summary on `ctx.res.send`. Implementation SHALL reside under `src/operations/access-expiration-reminders/` with entry module `index.ts`. The operation SHALL NOT apply the manager-selected `newExpirationDate` to ISC.

#### Scenario: Operation invoked with required formName

- **GIVEN** `custom:access-expiration-reminders` is declared in connector-spec.json and registered
- **WHEN** ISC invokes the command with input containing `formName` and standard `requestId`
- **THEN** the handler SHALL discover matching ACCESS_PROFILE expirations, create manager forms, persist notice accounts, and return reminder scan summary via `ctx.res.send`
- **AND** SHALL NOT persist rollup counters on identity `requestId`

#### Scenario: Default expirationDays

- **GIVEN** input omits `expirationDays`
- **WHEN** the handler matches assignments
- **THEN** `expirationDays` SHALL default to `1`

#### Scenario: Missing formName fails

- **GIVEN** input omits `formName` or supplies an empty string
- **WHEN** `custom:access-expiration-reminders` executes
- **THEN** the handler SHALL fail with ConnectorError indicating `formName` is required

#### Scenario: Auto-discovery registration

- **GIVEN** `src/operations/access-expiration-reminders/index.ts` declares `command: 'custom:access-expiration-reminders'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:access-expiration-reminders` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

### Requirement: UTC calendar-day expiration matching

The operation SHALL select ACCESS_PROFILE assignments where the exact difference in whole UTC calendar days between the run date (UTC) and the assignment `removeDate` (UTC calendar day) equals `expirationDays`. Matching SHALL NOT use rolling hour-based `Math.ceil` day calculations.

#### Scenario: Exact UTC day match

- **GIVEN** `expirationDays` is `1`
- **AND** an ACCESS_PROFILE assignment has `removeDate` on the next UTC calendar day relative to the run
- **WHEN** matching runs
- **THEN** that assignment SHALL be included

#### Scenario: Non-matching day excluded

- **GIVEN** `expirationDays` is `1`
- **AND** an ACCESS_PROFILE assignment has `removeDate` two UTC calendar days after the run
- **WHEN** matching runs
- **THEN** that assignment SHALL NOT be included

### Requirement: Expiration notice account per form

For each launched reminder form, the operation SHALL persist one result-source account with native identity `` `${requestId}:${identityId}:${accessProfileId}` ``. The notice account SHALL include `access-expiration-reminders:identityId`, `access-expiration-reminders:managerId`, `access-expiration-reminders:accessProfileId`, `access-expiration-reminders:removeDate`, `access-expiration-reminders:daysRemaining`, `access-expiration-reminders:form-url`, `access-expiration-reminders:form-email-header`, `access-expiration-reminders:form-email-body`, and `access-expiration-reminders:form-email-recipients`. The handler SHALL NOT persist a parent account on bare `requestId` for success rollup.

#### Scenario: Child persist per notice

- **GIVEN** identity `id-a` has ACCESS_PROFILE `ap-1` matching the threshold and a form is created for manager `mgr-1`
- **WHEN** the handler persists notice output
- **THEN** it SHALL call persist with identity `` `${requestId}:id-a:ap-1` ``
- **AND** child output SHALL include the identity, manager, access profile, removeDate, daysRemaining, and form/email fields listed above
- **AND** `form-email-recipients` SHALL be a string array containing the manager email

#### Scenario: Multiple profiles yield multiple accounts

- **GIVEN** one identity has two ACCESS_PROFILE assignments matching the threshold with resolvable manager email
- **WHEN** the handler completes within the form cap
- **THEN** it SHALL persist two distinct notice accounts
- **AND** SHALL create two form instances

### Requirement: Child persist account idempotency for reminders

The operation SHALL skip form launch and notice persist when a result-source account already exists for `` `${requestId}:${identityId}:${accessProfileId}` ``. Idempotency SHALL NOT query form instance state. Callers that require cross-run dedupe MUST reuse a stable `requestId`.

#### Scenario: Existing notice account skips form

- **GIVEN** an account already exists for `` `${requestId}:id-a:ap-1` ``
- **WHEN** the scan again matches that identity and access profile
- **THEN** the handler SHALL NOT create a new form instance
- **AND** SHALL increment the existing-account skip counter in the reminder scan summary

### Requirement: Manager recipient and email gate

The operation SHALL assign each reminder form to the identity’s manager (IDENTITY). When the manager cannot be resolved, or the manager has no resolvable email, the handler SHALL skip form launch and notice persist for that assignment and SHALL count the skip in the reminder scan summary. The operation SHALL NOT fail the entire invoke solely because one assignment lacks a manager or email.

#### Scenario: Missing manager skips

- **GIVEN** a matching ACCESS_PROFILE assignment on an identity with no manager id
- **WHEN** the handler processes that assignment
- **THEN** it SHALL NOT create a form
- **AND** SHALL increment the missing-manager/email skip counter

#### Scenario: Manager without email skips

- **GIVEN** a matching assignment whose manager id resolves but public email is empty
- **WHEN** the handler processes that assignment
- **THEN** it SHALL NOT create a form
- **AND** SHALL increment the missing-manager/email skip counter

### Requirement: Reminder form definition and instance

The operation SHALL ensure a form definition named by required input `formName` exists (seed fingerprint ensure/patch/create). Each form instance SHALL include form inputs `responseAccountId`, `identityId`, and `accessProfileId`, plus friendly situation context sufficient to explain the assignment and required action. The form SHALL require element key `newExpirationDate`. The form instance `expire` SHALL equal the assignment’s current `removeDate`. Form copy SHALL guide the manager that the new date must be after the current expiration; the operation SHALL NOT enforce that rule at form submit time.

#### Scenario: Form inputs include correlation keys

- **GIVEN** a form is launched for identity `id-a` and access profile `ap-1`
- **WHEN** the form instance is created
- **THEN** formInput SHALL include `responseAccountId` equal to `` `${requestId}:id-a:ap-1` ``
- **AND** SHALL include `identityId` equal to `id-a`
- **AND** SHALL include `accessProfileId` equal to `ap-1`

#### Scenario: Form expires at removeDate

- **GIVEN** an assignment `removeDate` of `2026-08-20T22:00:00Z`
- **WHEN** the form instance is created
- **THEN** the instance `expire` SHALL be `2026-08-20T22:00:00Z`

### Requirement: Form cap per invocation

The operation SHALL create at most 25 reminder forms per invocation. When additional matches remain after the cap, the handler SHALL stop creating forms, SHALL log a warning, and SHALL include an overflow count in the reminder scan summary.

#### Scenario: Cap reached

- **GIVEN** more than 25 matching assignments with resolvable managers and emails
- **AND** no existing notice accounts for those keys
- **WHEN** the handler reaches 25 forms created
- **THEN** it SHALL stop creating additional forms
- **AND** `ctx.res.send` SHALL include an overflow counter greater than zero

### Requirement: Reminder scan summary on invoke response

The operation SHALL return reminder scan summary counters on the successful command response via `ctx.res.send`, including identities scanned, expirations matched, forms created, existing-account skips, missing-manager/email skips, form launch failures, form persist failures, and cap overflow when applicable. Optional zero-valued failure/skip/overflow counters MAY be omitted when zero. The handler SHALL NOT persist the summary on identity `requestId`.

#### Scenario: Successful scan returns summary on res.send

- **GIVEN** a scan matches 3 expirations, creates 2 forms, skips 1 for existing account
- **WHEN** the handler completes successfully
- **THEN** `ctx.res.send` SHALL be called with `status: 'success'`
- **AND** the payload SHALL include identities-scanned, expirations-matched, forms-created, and existing-account skip counters under the `access-expiration-reminders:` prefix
- **AND** the handler SHALL NOT call `ctx.persist` with identity `requestId` for rollup counters

#### Scenario: Zero matches summary only

- **GIVEN** a scan finds no matching ACCESS_PROFILE expirations
- **WHEN** the handler completes successfully
- **THEN** `ctx.res.send` SHALL include expirations-matched equal to `0`
- **AND** SHALL NOT persist any expiration notice account

### Requirement: Offline and test mode support

The operation SHALL support offline fixtures for identities with sunset ACCESS_PROFILE assignments and managers suitable for local invoke and unit tests. In framework test mode, notice persist SHALL be inhibited per custom-operation-framework rules while form ensure/create behavior follows the same offline/test conventions as other form-launching operations.

#### Scenario: Offline invoke returns summary

- **GIVEN** offline invocation with valid `formName` and offline fixtures containing at least one matching assignment
- **WHEN** `custom:access-expiration-reminders` executes
- **THEN** the handler SHALL complete successfully
- **AND** `ctx.res.send` SHALL include reminder scan summary counters

### Requirement: Importable reminder workflows

The repository SHALL provide an importable scheduled Analysis workflow that invokes `custom:access-expiration-reminders` daily at 00:00 UTC with a stable `requestId`, required `formName`, and `expirationDays` of `1`, and an importable Notification workflow triggered by `idn:account-created` that filters on `operationName` equal to `custom:access-expiration-reminders` and sends email using persisted `form-email-*` attributes.

#### Scenario: Analysis workflow present

- **GIVEN** a developer inspects `workflows/`
- **WHEN** they look for access expiration reminder orchestration
- **THEN** an Analysis workflow JSON SHALL exist with schedule frequency daily at 00:00 UTC
- **AND** the invoke input SHALL include stable `requestId`, `formName`, and `expirationDays` of `1`

#### Scenario: Notification workflow present

- **GIVEN** a developer inspects `workflows/`
- **WHEN** they look for access expiration reminder email delivery
- **THEN** a Notification workflow JSON SHALL exist with `idn:account-created` trigger
- **AND** SHALL filter accounts whose `operationName` is `custom:access-expiration-reminders`
