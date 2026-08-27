## ADDED Requirements

### Requirement: Form email recipients term

The glossary SHALL define **form email recipients** as the multi-value persist output listing email addresses for ISC workflow Send Email `recipientEmailList` after SOD form launch operations.

#### Scenario: Preferred persist key spelling

- **GIVEN** specs or code name the recipient email persist output on `custom:sod-remediation` or `custom:access-sod-remediation`
- **WHEN** the ubiquitous language spec is read
- **THEN** the preferred attribute suffix SHALL be `form-email-recipients` (plural)
- **AND** the deprecated singular `form-email-recipient` SHALL NOT appear in normative text without a migration note

#### Scenario: Type is string array

- **GIVEN** documentation describes the form email recipients persist field
- **WHEN** the type is stated
- **THEN** it SHALL be described as `string[]` suitable for multi-value STRING account attributes with `isMulti: true`
