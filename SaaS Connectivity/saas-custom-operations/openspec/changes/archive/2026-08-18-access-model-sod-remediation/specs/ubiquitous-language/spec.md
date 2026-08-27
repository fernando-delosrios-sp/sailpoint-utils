## ADDED Requirements

### Requirement: Access model scan summary term

The glossary SHALL define **scan summary** as the rollup counters returned on the successful `custom:access-model-sod-remediation` invoke response via `ctx.res.send`, comprising `access-model-sod-remediation:access-items-scanned`, `access-model-sod-remediation:violations-found`, and optional `access-model-sod-remediation:forms-skipped` and `access-model-sod-remediation:forms-persist-failed`. The scan summary SHALL NOT be persisted as a result-source account on `requestId`.

#### Scenario: Scan summary term

- **GIVEN** specs or code refer to rollup counts from an access-model scan invoke
- **WHEN** normative text names the delivery mechanism
- **THEN** it SHALL use **scan summary** for the invoke response payload
- **AND** SHALL NOT describe rollup counters as a parent or summary result-source account on `requestId`

---

## MODIFIED Requirements

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
- **THEN** child per-form keys SHALL use prefix `access-model-sod-remediation:`
- **AND** scan rollup counters SHALL be described as **scan summary** on the invoke response, not as persisted attributes on `requestId`
- **AND** the deprecated prefix `access-sod-remediation:` SHALL NOT appear in normative text without a migration note

#### Scenario: SoD form HTML shared usage

- **GIVEN** documentation describes which operations use shared sod-form-html builders
- **WHEN** the access-model scan operation is listed
- **THEN** it SHALL name `custom:access-model-sod-remediation` alongside `custom:sod-remediation`

---

## REMOVED Requirements

_(none)_
