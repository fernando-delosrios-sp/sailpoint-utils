## MODIFIED Requirements

### Requirement: Form email recipients term

The glossary SHALL define **form email recipients** as the multi-value persist output listing email addresses for ISC workflow Send Email `recipientEmailList` after SOD form launch operations.

#### Scenario: Preferred persist key spelling

- **GIVEN** specs or code name the recipient email persist output on `custom:sod-remediation` or `custom:access-model-sod-remediation`
- **WHEN** the ubiquitous language spec is read
- **THEN** the preferred attribute suffix SHALL be `form-email-recipients` (plural)
- **AND** the deprecated singular `form-email-recipient` SHALL NOT appear in normative text without a migration note

#### Scenario: Type is string array

- **GIVEN** documentation describes the form email recipients persist field
- **WHEN** the type is stated
- **THEN** it SHALL be described as `string[]` suitable for multi-value STRING account attributes with `isMulti: true`

## ADDED Requirements

### Requirement: Access model SoD remediation term

The glossary SHALL define **access model SoD remediation** as the proactive catalog scan custom operation that detects intrinsic SoD violations on enabled roles and access profiles and creates policy-owner remediation forms via `custom:access-model-sod-remediation`.

#### Scenario: Preferred command spelling

- **GIVEN** specs or code name the access-model scan operation
- **WHEN** the ubiquitous language spec is read
- **THEN** the preferred command SHALL be `custom:access-model-sod-remediation`
- **AND** the deprecated `custom:access-sod-remediation` SHALL NOT appear in normative text without a migration note

#### Scenario: Persist namespace spelling

- **GIVEN** documentation names persist output keys for the access-model scan operation
- **WHEN** the prefix is stated
- **THEN** it SHALL be `access-model-sod-remediation:`
- **AND** the deprecated prefix `access-sod-remediation:` SHALL NOT appear in normative text without a migration note

#### Scenario: SoD form HTML shared usage

- **GIVEN** documentation describes which operations use shared sod-form-html builders
- **WHEN** the access-model scan operation is listed
- **THEN** it SHALL name `custom:access-model-sod-remediation` alongside `custom:sod-remediation`
