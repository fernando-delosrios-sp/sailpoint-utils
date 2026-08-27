# form-notification Specification

## Purpose
Typed form notification envelope and prefix-scoped persist mapping for standalone form launch outputs consumed by ISC workflows.

## Requirements
### Requirement: Form notification envelope

The connector SHALL provide a typed **form notification envelope** under `src/lib/form-notification/` holding `formUrl`, `emailHeader`, `emailBody`, and `emailRecipients` (`string[]`). The module SHALL map an envelope to namespaced persist attributes using an operation prefix. It SHALL NOT invoke ISC APIs or resolve recipient emails.

#### Scenario: Persist attribute mapping

- **GIVEN** prefix `sod-remediation` and a complete form notification envelope
- **WHEN** the persist mapper is invoked
- **THEN** the result SHALL include keys `sod-remediation:form-url`, `sod-remediation:form-email-header`, `sod-remediation:form-email-body`, and `sod-remediation:form-email-recipients`
- **AND** values SHALL match the envelope fields (`emailRecipients` as `string[]`)

#### Scenario: Access-model prefix mapping

- **GIVEN** prefix `access-model-sod-remediation` and a complete envelope
- **WHEN** the persist mapper is invoked
- **THEN** the four keys SHALL use that prefix with the same suffixes

#### Scenario: Expiration reminders prefix mapping

- **GIVEN** prefix `access-expiration-reminders` and a complete envelope
- **WHEN** the persist mapper is invoked
- **THEN** the four keys SHALL use that prefix with the same suffixes

#### Scenario: Recipients remain string array

- **GIVEN** an envelope with a single recipient email
- **WHEN** mapped to persist attributes
- **THEN** `form-email-recipients` SHALL be a one-element `string[]`
- **AND** SHALL NOT be flattened to a bare string

#### Scenario: No ISC side effects

- **GIVEN** form-notification helpers
- **WHEN** invoked
- **THEN** they SHALL NOT call ISC or Forms APIs
