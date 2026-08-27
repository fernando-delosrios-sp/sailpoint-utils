## ADDED Requirements

### Requirement: Access item owner term

The glossary SHALL define **access item owner** as the IDENTITY-typed primary owner of a catalog access item (role or access profile). For `custom:access-model-sod-remediation`, the access item owner is the form instance recipient and the sole source of `form-email-recipients`.

#### Scenario: Access item owner is form audience

- **GIVEN** documentation describes who receives access-model SoD remediation forms
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL use **access item owner**
- **AND** SHALL NOT describe the form recipient as the SoD policy owner

#### Scenario: Distinct from form definition owner

- **GIVEN** documentation distinguishes form definition ownership from form instance recipient
- **WHEN** the terms are compared
- **THEN** **access item owner** SHALL mean the catalog item owner used as form recipient
- **AND** SHALL NOT mean the access-token identity that owns the shared form definition on create

## MODIFIED Requirements

### Requirement: Access model SoD remediation term

The glossary SHALL define **access model SoD remediation** as the proactive catalog scan custom operation that detects intrinsic SoD violations on enabled roles and access profiles and creates access-item-owner remediation forms via `custom:access-model-sod-remediation`.

#### Scenario: Preferred command spelling

- **GIVEN** specs or code name the access-model scan operation
- **WHEN** the ubiquitous language spec is read
- **THEN** the preferred command SHALL be `custom:access-model-sod-remediation`
- **AND** the deprecated `custom:access-sod-remediation` SHALL NOT appear in normative text without a migration note

#### Scenario: Persist namespace spelling

- **GIVEN** documentation names persist output keys for the access-model scan operation
- **WHEN** the prefix is stated
- **THEN** child per-form keys SHALL use prefix `access-model-sod-remediation:`
- **AND** scan rollup counters SHALL be described as **scan summary** on the invoke response, not as persisted attributes on `requestId`
- **AND** the deprecated prefix `access-sod-remediation:` SHALL NOT appear in normative text without a migration note

#### Scenario: SoD form HTML shared usage

- **GIVEN** documentation describes which operations use shared sod-form-html builders
- **WHEN** the access-model scan operation is listed
- **THEN** it SHALL name `custom:access-model-sod-remediation` alongside `custom:sod-remediation`
